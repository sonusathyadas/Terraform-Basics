
provider "aws" {
    profile = "default"
    region = "ap-south-1"
}
# Create an IAM user with Administrator access and Access Key
resource "aws_iam_user" "developer_user" {
    name = "devuser"
    tags = {
        Name = "Developer User"
    }
}

resource "aws_iam_user_policy_attachment" "attach_admin_policy" {
  user       = aws_iam_user.developer_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "devuser_key" {
    user = aws_iam_user.developer_user.name
}