$AWS_REGION = "ap-northeast-1"

$AWS_CREDENTIAL = "aws-auto-backup-credential"

$BACKUP_NAME = "AutoBackup"

$BACKUP_CLEANUP_DAY = 7

$SNAPSHOT_DESCRIPTION = "AutoBackup"

$TARGET_VOLUME_LIST = @("MY_VOLUME")

# $AWS_ACCESS_KEY = ""
# $AWS_SECRET_KEY = ""

# Set-AWSCredentials -AccessKey $AWS_ACCESS_KEY -SecretKey $AWS_SECRET_KEY -StoreAs $AWS_CREDENTIAL
