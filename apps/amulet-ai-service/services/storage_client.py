import os
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config
from typing import Optional, List
import json
import structlog

logger = structlog.get_logger()

class StorageClient:
    def __init__(self):
        endpoint = os.getenv("S3_ENDPOINT", "ceph-rgw:9000")
        access_key = os.getenv("S3_ACCESS_KEY", "demo_access_key")
        secret_key = os.getenv("S3_SECRET_KEY", "demo_secret_key")
        secure = os.getenv("S3_SECURE", "false").lower() == "true"
        region = os.getenv("S3_REGION", "us-east-1")
        
        # Check if in test mode - skip initialization if storage not available
        self.test_mode = os.getenv("USE_SQLITE", "false").lower() == "true"
        
        # Build endpoint URL
        protocol = "https" if secure else "http"
        endpoint_url = f"{protocol}://{endpoint}"
        
        # Configure boto3 client
        config = Config(
            signature_version='s3v4',
            s3={'addressing_style': 'path'}
        )
        
        self.client = boto3.client(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
            config=config
        )
        
        # Only ensure buckets if not in test mode or if storage is available
        if not self.test_mode:
            self._ensure_buckets()
    
    def _ensure_buckets(self):
        """Create default buckets if they don't exist"""
        buckets = ["images", "datasets", "models", "results", "metadata", "logs"]
        for bucket in buckets:
            try:
                # Check if bucket exists
                self.client.head_bucket(Bucket=bucket)
                logger.info("bucket_exists", bucket=bucket)
            except ClientError as e:
                error_code = e.response.get('Error', {}).get('Code', '')
                if error_code == '404':
                    # Bucket doesn't exist, create it
                    try:
                        self.client.create_bucket(Bucket=bucket)
                        logger.info("created_bucket", bucket=bucket)
                    except ClientError as create_error:
                        logger.error("bucket_creation_failed", bucket=bucket, error=str(create_error))
                else:
                    logger.error("bucket_check_failed", bucket=bucket, error=str(e))
            except Exception as e:
                # Connection error - skip in test mode
                if self.test_mode:
                    logger.warning("storage_unavailable_test_mode", bucket=bucket)
                    return
                else:
                    raise
    
    def upload_image(self, bucket: str, object_name: str, data: bytes, content_type: str = "image/jpeg") -> str:
        """Upload image to storage"""
        if self.test_mode:
            # Mock upload in test mode
            logger.info("storage_upload_mocked", bucket=bucket, object_name=object_name)
            return f"{bucket}/{object_name}"
        
        try:
            self.client.put_object(
                Bucket=bucket,
                Key=object_name,
                Body=data,
                ContentType=content_type
            )
            return f"{bucket}/{object_name}"
        except ClientError as e:
            logger.error("upload_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def upload_file(self, bucket: str, object_name: str, file_path: str, content_type: Optional[str] = None) -> str:
        """Upload file from filesystem to storage"""
        try:
            extra_args = {}
            if content_type:
                extra_args['ContentType'] = content_type
            
            self.client.upload_file(
                Filename=file_path,
                Bucket=bucket,
                Key=object_name,
                ExtraArgs=extra_args if extra_args else None
            )
            return f"{bucket}/{object_name}"
        except ClientError as e:
            logger.error("upload_file_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def download_file(self, bucket: str, object_name: str) -> bytes:
        """Download file from storage"""
        if self.test_mode:
            # Mock download in test mode
            logger.info("storage_download_mocked", bucket=bucket, object_name=object_name)
            return b"mock file content"
        
        try:
            response = self.client.get_object(Bucket=bucket, Key=object_name)
            data = response['Body'].read()
            return data
        except ClientError as e:
            logger.error("download_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def upload_json(self, bucket: str, object_name: str, data: dict) -> str:
        """Upload JSON data to storage"""
        if self.test_mode:
            # Mock upload in test mode
            logger.info("storage_json_upload_mocked", bucket=bucket, object_name=object_name)
            return f"{bucket}/{object_name}"
        
        try:
            json_str = json.dumps(data, ensure_ascii=False)
            json_bytes = json_str.encode('utf-8')
            
            self.client.put_object(
                Bucket=bucket,
                Key=object_name,
                Body=json_bytes,
                ContentType="application/json"
            )
            return f"{bucket}/{object_name}"
        except ClientError as e:
            logger.error("upload_json_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def download_json(self, bucket: str, object_name: str) -> dict:
        """Download and parse JSON from storage"""
        try:
            data = self.download_file(bucket, object_name)
            return json.loads(data.decode('utf-8'))
        except Exception as e:
            logger.error("download_json_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def list_objects(self, bucket: str, prefix: str = "", recursive: bool = True) -> List[str]:
        """List objects in bucket with optional prefix"""
        if self.test_mode:
            # Mock list in test mode
            logger.info("storage_list_mocked", bucket=bucket, prefix=prefix)
            return []
        
        try:
            object_names = []
            paginator = self.client.get_paginator('list_objects_v2')
            
            page_iterator = paginator.paginate(
                Bucket=bucket,
                Prefix=prefix
            )
            
            for page in page_iterator:
                if 'Contents' in page:
                    for obj in page['Contents']:
                        object_names.append(obj['Key'])
            
            return object_names
        except ClientError as e:
            logger.error("list_objects_failed", bucket=bucket, prefix=prefix, error=str(e))
            return []
    
    def delete_object(self, bucket: str, object_name: str) -> bool:
        """Delete object from storage"""
        try:
            self.client.delete_object(Bucket=bucket, Key=object_name)
            return True
        except ClientError as e:
            logger.error("delete_failed", bucket=bucket, object_name=object_name, error=str(e))
            return False
    
    def get_presigned_url(self, bucket: str, object_name: str, expires_seconds: int = 3600) -> str:
        """Generate presigned URL for temporary access"""
        if self.test_mode:
            # Mock presigned URL in test mode
            return f"http://localhost:9010/{bucket}/{object_name}?mock=true"
        
        try:
            url = self.client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucket, 'Key': object_name},
                ExpiresIn=expires_seconds
            )
            return url
        except ClientError as e:
            logger.error("presigned_url_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def object_exists(self, bucket: str, object_name: str) -> bool:
        """Check if object exists"""
        try:
            self.client.head_object(Bucket=bucket, Key=object_name)
            return True
        except ClientError:
            return False

# Singleton instance
storage_client = StorageClient()
