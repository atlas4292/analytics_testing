"""
MinIO S3-Compatible Storage Client
Example usage for connecting to local MinIO from your analytics projects
"""

import boto3
from botocore.config import Config
from botocore.exceptions import NoCredentialsError
import pandas as pd

class MinIOClient:
    """Local S3-compatible storage client using MinIO"""
    
    def __init__(self, 
                 endpoint_url="http://localhost:9000",
                 access_key="minioadmin",
                 secret_key="minioadmin123",
                 region="us-east-1"):
        """Initialize MinIO client"""
        self.endpoint_url = endpoint_url
        self.access_key = access_key
        self.secret_key = secret_key
        self.region = region
        
        # Configure boto3 client
        self.client = boto3.client(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
            config=Config(signature_version='s3v4')
        )
        
        # Also create a resource for higher-level operations
        self.resource = boto3.resource(
            's3',
            endpoint_url=endpoint_url,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region,
            config=Config(signature_version='s3v4')
        )
    
    def list_buckets(self):
        """List all available buckets"""
        try:
            response = self.client.list_buckets()
            return [bucket['Name'] for bucket in response['Buckets']]
        except Exception as e:
            print(f"Error listing buckets: {e}")
            return []
    
    def upload_file(self, file_path, bucket, key):
        """Upload a file to MinIO"""
        try:
            self.client.upload_file(file_path, bucket, key)
            print(f"✅ Uploaded {file_path} to {bucket}/{key}")
            return True
        except Exception as e:
            print(f"❌ Upload failed: {e}")
            return False
    
    def upload_dataframe(self, df, bucket, key, format='parquet'):
        """Upload a pandas DataFrame to MinIO"""
        try:
            if format == 'parquet':
                buffer = df.to_parquet()
                self.client.put_object(Body=buffer, Bucket=bucket, Key=key)
            elif format == 'csv':
                csv_buffer = df.to_csv(index=False)
                self.client.put_object(Body=csv_buffer, Bucket=bucket, Key=key)
            else:
                raise ValueError(f"Unsupported format: {format}")
                
            print(f"✅ Uploaded DataFrame to {bucket}/{key}")
            return True
        except Exception as e:
            print(f"❌ DataFrame upload failed: {e}")
            return False
    
    def download_file(self, bucket, key, local_path):
        """Download a file from MinIO"""
        try:
            self.client.download_file(bucket, key, local_path)
            print(f"✅ Downloaded {bucket}/{key} to {local_path}")
            return True
        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False
    
    def read_dataframe(self, bucket, key, format='parquet'):
        """Read a DataFrame from MinIO"""
        try:
            obj = self.client.get_object(Bucket=bucket, Key=key)
            
            if format == 'parquet':
                df = pd.read_parquet(obj['Body'])
            elif format == 'csv':
                df = pd.read_csv(obj['Body'])
            else:
                raise ValueError(f"Unsupported format: {format}")
                
            print(f"✅ Read DataFrame from {bucket}/{key}")
            return df
        except Exception as e:
            print(f"❌ DataFrame read failed: {e}")
            return None
    
    def list_objects(self, bucket, prefix=""):
        """List objects in a bucket"""
        try:
            response = self.client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix
            )
            if 'Contents' in response:
                return [(obj['Key'], obj['Size']) for obj in response['Contents']]
            return []
        except Exception as e:
            print(f"❌ List objects failed: {e}")
            return []


def example_usage():
    """Example of how to use MinIO in your analytics projects"""
    
    # Initialize client
    minio = MinIOClient()
    
    # List available buckets
    print("📁 Available buckets:")
    buckets = minio.list_buckets()
    for bucket in buckets:
        print(f"  - {bucket}")
    
    # Create sample data
    sample_data = pd.DataFrame({
        'id': range(1, 101),
        'value': [i * 2 for i in range(1, 101)],
        'category': ['A', 'B', 'C'] * 33 + ['A']
    })
    
    # Upload DataFrame
    minio.upload_dataframe(
        df=sample_data,
        bucket='analytics-data',
        key='sample/test_data.parquet',
        format='parquet'
    )
    
    # Read it back
    df_read = minio.read_dataframe(
        bucket='analytics-data',
        key='sample/test_data.parquet',
        format='parquet'
    )
    
    if df_read is not None:
        print(f"📊 Data shape: {df_read.shape}")
        print(df_read.head())
    
    # List objects in bucket
    print("\n📄 Files in analytics-data bucket:")
    objects = minio.list_objects('analytics-data')
    for key, size in objects:
        print(f"  - {key} ({size} bytes)")


if __name__ == "__main__":
    example_usage()