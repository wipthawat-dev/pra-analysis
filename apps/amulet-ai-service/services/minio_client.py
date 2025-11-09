import os
from minio import Minio
from minio.error import S3Error
from typing import Optional, BinaryIO, List
import json
import structlog

logger = structlog.get_logger()

class MinIOClient:
    def __init__(self):
        endpoint = os.getenv("MINIO_ENDPOINT", "minio:9000")
        access_key = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
        secret_key = os.getenv("MINIO_SECRET_KEY", "minioadmin")
        secure = os.getenv("MINIO_SECURE", "false").lower() == "true"
        
        self.client = Minio(
            endpoint,
            access_key=access_key,
            secret_key=secret_key,
            secure=secure
        )
        self._ensure_buckets()
    
    def _ensure_buckets(self):
        """Create default buckets if they don't exist"""
        buckets = ["images", "datasets", "models", "results", "metadata", "logs"]
        for bucket in buckets:
            try:
                if not self.client.bucket_exists(bucket):
                    self.client.make_bucket(bucket)
                    logger.info("created_bucket", bucket=bucket)
            except S3Error as e:
                logger.error("bucket_creation_failed", bucket=bucket, error=str(e))
    
    def upload_image(self, bucket: str, object_name: str, data: bytes, content_type: str = "image/jpeg") -> str:
        """Upload image to MinIO"""
        try:
            from io import BytesIO
            self.client.put_object(
                bucket,
                object_name,
                BytesIO(data),
                length=len(data),
                content_type=content_type
            )
            return f"{bucket}/{object_name}"
        except S3Error as e:
            logger.error("upload_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def upload_file(self, bucket: str, object_name: str, file_path: str, content_type: Optional[str] = None) -> str:
        """Upload file from filesystem to MinIO"""
        try:
            import os
            file_size = os.path.getsize(file_path)
            with open(file_path, 'rb') as file_data:
                self.client.put_object(
                    bucket,
                    object_name,
                    file_data,
                    length=file_size,
                    content_type=content_type
                )
            return f"{bucket}/{object_name}"
        except S3Error as e:
            logger.error("upload_file_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def download_file(self, bucket: str, object_name: str) -> bytes:
        """Download file from MinIO"""
        try:
            response = self.client.get_object(bucket, object_name)
            data = response.read()
            response.close()
            response.release_conn()
            return data
        except S3Error as e:
            logger.error("download_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def upload_json(self, bucket: str, object_name: str, data: dict) -> str:
        """Upload JSON data to MinIO"""
        try:
            json_str = json.dumps(data, ensure_ascii=False)
            json_bytes = json_str.encode('utf-8')
            from io import BytesIO
            self.client.put_object(
                bucket,
                object_name,
                BytesIO(json_bytes),
                length=len(json_bytes),
                content_type="application/json"
            )
            return f"{bucket}/{object_name}"
        except S3Error as e:
            logger.error("upload_json_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def download_json(self, bucket: str, object_name: str) -> dict:
        """Download and parse JSON from MinIO"""
        try:
            data = self.download_file(bucket, object_name)
            return json.loads(data.decode('utf-8'))
        except Exception as e:
            logger.error("download_json_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def list_objects(self, bucket: str, prefix: str = "", recursive: bool = True) -> List[str]:
        """List objects in bucket with optional prefix"""
        try:
            objects = self.client.list_objects(bucket, prefix=prefix, recursive=recursive)
            return [obj.object_name for obj in objects]
        except S3Error as e:
            logger.error("list_objects_failed", bucket=bucket, prefix=prefix, error=str(e))
            return []
    
    def delete_object(self, bucket: str, object_name: str) -> bool:
        """Delete object from MinIO"""
        try:
            self.client.remove_object(bucket, object_name)
            return True
        except S3Error as e:
            logger.error("delete_failed", bucket=bucket, object_name=object_name, error=str(e))
            return False
    
    def get_presigned_url(self, bucket: str, object_name: str, expires_seconds: int = 3600) -> str:
        """Generate presigned URL for temporary access"""
        try:
            from datetime import timedelta
            url = self.client.presigned_get_object(bucket, object_name, expires=timedelta(seconds=expires_seconds))
            return url
        except S3Error as e:
            logger.error("presigned_url_failed", bucket=bucket, object_name=object_name, error=str(e))
            raise
    
    def object_exists(self, bucket: str, object_name: str) -> bool:
        """Check if object exists"""
        try:
            self.client.stat_object(bucket, object_name)
            return True
        except S3Error:
            return False

# Singleton instance
minio_client = MinIOClient()

