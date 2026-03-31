# Sport Rental Web Deployment with Terraform on Azure

## สิ่งที่ต้องเตรียมก่อนรัน
1. ติดตั้ง Terraform
2. ติดตั้ง Azure CLI

3. สมัคร Account Azure
    Login Azure ด้วยคำสั่ง
   ```bash
   az login
   ```
4. สร้าง SSH key หรือมี public key อยู่แล้ว
5. เตรียม Git repository ของเว็บโปรเจกต์
6. ตรวจสอบว่าใน repo มีไฟล์ SQL เช่น `sports_rental_system.sql`


---
## 1: Login Azure
az login

หลังจาก login แล้ว สามารถตรวจสอบ account ได้:

az account show

ถ้ามีหลาย subscription:

az account set --subscription "ชื่อหรือ ID"
## 2: Clone Repository
git clone https://github.com/USERNAME/repo-terraform-azure.git
cd repo-terraform-azure

## 3: สร้าง SSH Key
ssh-keygen -t rsa -b 4096

จากนั้น copy public key:

cat ~/.ssh/id_rsa.pub
## 4: ตั้งค่า terraform.tfvars

สร้างไฟล์:

cp terraform.tfvars.example terraform.tfvars

แก้ไขไฟล์:

resource_group_name = "rg-sport-rental"
location            = "East Asia"
vm_name             = "vm-sport-web"
vm_size             = "Standard_B1s"
admin_username      = "azureuser"

public_key = "ใส่ SSH PUBLIC KEY ตรงนี้"

app_port = 80
## 5: Initialize Terraform
terraform init
## 6: ตรวจสอบ Plan
terraform plan
## 7: Deploy ระบบ
terraform apply

พิมพ์:

yes
## 8: ตรวจสอบ Output
terraform output

ตัวอย่าง:

public_ip = "20.xxx.xxx.xxx"
customer_url = "http://20.xxx.xxx.xxx/customer/frontend/login.html"
## 9: เข้าใช้งานระบบ

เปิดผ่าน browser:

http://<public-ip>

หรือ:

Customer:
http://<ip>/customer/frontend/login.html
Staff:
http://<ip>/staff/frontend/login.html
Warehouse:
http://<ip>/warehouse/frontend/login.html
Executive:
http://<ip>/executive/frontend/login.html
🧪 STEP 10: ทดสอบระบบ

## 10 ทดสอบการเข้าสู่ระบบ

หลังจากหน้าเว็บแสดงผลแล้ว สามารถใช้บัญชีตัวอย่างสำหรับทดสอบระบบได้ดังนี้

| บทบาทผู้ใช้       | Email                          | Password       |
| ----------------| ------------------------------| -----  |
| Staff | apichat@kku.ac.th | hashed_pw012 | 
| Customer | Thirawaty66@nu.ac.th | nu000000 |
| Warehouse Manager | kamonchanok@ku.ac.th | hashed_pw024 |
| Rector | krisana@tu.ac.th | hashed_pw020 |
| Executive | winai@nu.ac.th | winai_jaidee |


บัญชีเหล่านี้ใช้สำหรับทดสอบฟังก์ชันของระบบภายในขอบเขตของโครงการเท่านั้น

## 11 ลบทรัพยากรเมื่อใช้งานเสร็จ

เมื่อทดสอบเสร็จและไม่ต้องการใช้งานทรัพยากรบน Azure ต่อแล้ว สามารถลบทุกอย่างที่ Terraform สร้างไว้ได้ด้วยคำสั่ง

```bash
terraform destroy
```

จากนั้นพิมพ์

```bash
yes
```