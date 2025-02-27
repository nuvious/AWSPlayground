import os
import sys

import boto3

def generate_file(file_path, size_in_gb):
    os.system(f"fallocate -l {1024 * 1024 * 1024 * size_in_gb} {file_path}")

def main():
    if len(sys.argv) != 2:
        print("upload_file.py BUCKET_NAME")
        sys.exit(1)

    bucket_name = sys.argv[1]
    file_name = "file.dat"

    file_path = f"/tmp/{file_name}"
    generate_file(file_path, 8)

    print(f"Uploading {file_name} to S3 bucket {bucket_name}")
    s3_client = boto3.client('s3')
    # extra_args = {'ChecksumAlgorithm': 'CRC64NVME'}
    extra_args = {}
    s3_client.upload_file(file_path, bucket_name, file_name, ExtraArgs=extra_args)

    os.remove(file_path)

if __name__ == "__main__":
    main()
