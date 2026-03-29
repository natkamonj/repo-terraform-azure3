 # Web Sport Rental System (Terraform + Azure)

## เครื่องมือที่ต้องติดตั้ง

- Terraform CLI
- Azure CLI
- สมัคร Account Azure

---

## 1. Login Azure

เปิด Terminal แล้วรัน:

```bash
az login
```

---

## 2. สร้าง SSH Key (ถ้ายังไม่มี)

รันคำสั่ง:

```bash
ssh-keygen -t rsa -b 4096
```

ค่าเริ่มต้นที่ใช้ในโปรเจค:

- Private key: `~/.ssh/id_rsa`
- Public key: `~/.ssh/id_rsa.pub`

---

## 3. เตรียม Terraform Project

สร้างไฟล์:

```text
main.tf
variables.tf
outputs.tf
terraform.tfvars
```

จากนั้นนำโค้ดของโปรเจคใส่ลงในแต่ละไฟล์ให้เรียบร้อย

---

## 4. แก้ไขค่าใน `terraform.tfvars`

ตัวอย่างค่าที่ต้องกำหนด:

```hcl
location       = "Southeast Asia"
vm_size        = "Standard_B1s"
admin_username = "azureuser"
ssh_public_key = "~/.ssh/id_rsa.pub"
```

สำคัญ: ต้องใช้ path ของ public key ให้ถูกต้อง คือ `~/.ssh/id_rsa.pub`

---

## 5. โครงสร้างไฟล์ Terraform

### `variables.tf`

ใช้กำหนดค่าต่าง ๆ เช่น:

- location
- vm size
- username
- ssh key

### `main.tf`

กำหนดทรัพยากรหลัก เช่น:

- Azure Provider
- Resource Group
- Virtual Network และ Subnet
- Public IP
- Network Security Group (เปิด port 22, 80)
- Linux Virtual Machine

และทำการตั้งค่าระบบภายใน VM เช่น:

- ติดตั้ง Apache / PHP / MySQL
- Clone โปรเจคจาก GitHub
- Import Database
- เชื่อมต่อหน้าเว็บกับฐานข้อมูล

### `outputs.tf`

ใช้แสดงค่า:

- Public IP
- URL สำหรับเข้าใช้งานระบบ

---

## 6. Deploy ด้วย Terraform

ไปที่โฟลเดอร์โปรเจค แล้วรัน:

```bash
terraform init
terraform plan
terraform apply
```

เมื่อระบบถาม ให้พิมพ์:

```text
yes
```

---

## 7. รอระบบติดตั้งให้เสร็จ

หลังจาก `terraform apply` สำเร็จแล้ว

ให้รอประมาณ **5 นาที** ก่อนเปิดหน้าเว็บ  
เพื่อให้ VM ทำการติดตั้ง package, clone project และ import database ให้เรียบร้อย

---

## 8. เข้าใช้งานระบบ

รันคำสั่ง:

```bash
terraform output
```

จะได้ค่า Public IP ของเครื่อง

เปิดใน browser:

```text
http://<public-ip>/customer/frontend/login.html
http://<public-ip>/staff/frontend/login.html
http://<public-ip>/warehouse/frontend/login.html
http://<public-ip>/executive/frontend/login.html
```

ตัวอย่าง:

```text
http://20.123.45.67/customer/frontend/login.html
http://20.123.45.67/staff/frontend/login.html
http://20.123.45.67/warehouse/frontend/login.html
http://20.123.45.67/executive/frontend/login.html
```

---

## 9. ลบ Infrastructure

เมื่อต้องการลบทรัพยากรทั้งหมด ให้รัน:

```bash
terraform destroy
```

จากนั้นพิมพ์:

```text
yes
```

---

## 10. Test Accounts

| Role | Email | Password |
|------|------|---------|
| Staff | rattana@nu.ac.th | rattana_jaidee |
| Customer | Thirawaty66@nu.ac.th | nu000000 |
| Warehouse Manager | sumet@nu.ac.th | sumet_jaidee |
| Rector | somchai@nu.ac.th | hashed_pw004 |
| Executive | winai@nu.ac.th | winai_jaidee |

---

## หมายเหตุเพิ่มเติม

- ถ้าเข้าเว็บไม่ได้ทันที ให้รอเพิ่มอีก 2–3 นาที
- ตรวจสอบว่า Azure VM อยู่ในสถานะ Running
- ตรวจสอบว่าเปิด port 80 และ 22 แล้ว
- ตรวจสอบว่า public IP ถูกต้องจากคำสั่ง `terraform output`
