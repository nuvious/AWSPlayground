import concurrent.futures
import json
import os
import sys

import boto3

def generate_file(file_path, size_in_gb):
    os.system(f"fallocate -l {1024 * 1024 * 1024 * size_in_gb} {file_path}")

def chunk_file(file_path, chunk_size=8 * 1024 * 1024):
    with open(file_path, 'rb') as f:
        chunk_number = 1
        while chunk := f.read(chunk_size):
            yield chunk_number, chunk
            chunk_number += 1


def upload_file_multipart(bucket_name, file_path, file_name):
    s3_client = boto3.client('s3')

    part_info = {
        'Parts': []
    }

    create_response = s3_client.create_multipart_upload(
        Bucket=bucket_name,
        Key=file_name,
        ChecksumAlgorithm='CRC64NVME'
    )

    upload_id = create_response['UploadId']

    
    for chunk_number, chunk in chunk_file(file_path):
        response = s3_client.upload_part(
            Bucket=bucket_name,
            Body=chunk,
            UploadId=upload_id,
            PartNumber=chunk_number,
            Key=file_name,
            ChecksumAlgorithm='CRC64NVME'
        )
        part = {
            'PartNumber': chunk_number,
            'ETag': response['ETag']
        }
        print(f"Completed part {part}", file=sys.stderr)
        part_info['Parts'].append(part)

    with open('parts.json', 'w', encoding='utf8') as f:
        json.dump(part_info, f)

    result = s3_client.complete_multipart_upload(
        Bucket=bucket_name,
        Key=file_name,
        UploadId=upload_id,
        MultipartUpload=part_info
    )

    with open('result.json', 'w', encoding='utf8') as f:
        json.dump(result, f)

def main():
    if len(sys.argv) != 2:
        print("upload_file.py BUCKET_NAME")
        sys.exit(1)

    bucket_name = sys.argv[1]
    file_name = "file.dat"

    file_path = f"/tmp/{file_name}"
    generate_file(file_path, 8)

    print(f"Uploading {file_name} to S3 bucket {bucket_name}")
    upload_file_multipart(bucket_name, file_path, file_name)

    os.remove(file_path)

if __name__ == "__main__":
    main()
