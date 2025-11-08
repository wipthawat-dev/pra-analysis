# Minimal starter MMDetection config placeholder (Apache-2.0)
num_classes = 1  # "amulet"
img_scale = (1024, 1024)

model = dict(
    type='FasterRCNN',
    backbone=dict(type='ResNet50', depth=50, num_stages=4, out_indices=(0,1,2,3)),
    roi_head=dict(
        bbox_head=dict(type='Shared2FCBBoxHead', num_classes=num_classes)
    )
)

data = dict(train=dict(ann_file='path/to/train.json', img_prefix='path/to/train/'),
            val=dict(ann_file='path/to/val.json', img_prefix='path/to/val/'),
            test=dict(ann_file='path/to/test.json', img_prefix='path/to/test/'))

work_dir = './work_dirs/amulet_det_r50_v0'
