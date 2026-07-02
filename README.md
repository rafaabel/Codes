# Codes

A collection of scripts and tools developed by **Rafael Abel** for Microsoft Identity and Infrastructure administration, automation, and day-to-day IT operations.

This repository brings together PowerShell scripts used for managing **Active Directory**, **Entra ID (Azure AD)**, **Active Directory Certificate Services (AD CS)**, along with study materials and exercises from technical courses.

## 📁 Repository Structure

### `AAD/` — Microsoft Entra ID (Azure AD)
PowerShell scripts for managing and monitoring Entra ID, including:
- App registration secret and certificate management (audit, alerting, and cleanup)
- Guest account reports
- Conditional Access policy exports
- Microsoft 365 Groups activity and quota reports
- Automated email notifications (SMTP, SendGrid, and Postman-based) for sync status and expiring credentials

### `ADCS/` — Active Directory Certificate Services
Scripts for auditing and reporting on certificate requests issued by certificate templates.

### `ADDS/` — Active Directory Domain Services
Organized into two categories:
- **Day-to-Day operations**: Scripts for common AD administrative tasks such as user and group management, account lockout troubleshooting, password management, ACL scanning, inactive account handling, GPO and domain controller inventory, and system health data collection.
- **Health Check**: Scripts focused on AD infrastructure health, including DFSR backlog monitoring, event ID analysis, and overall domain health checks.

### `Courses/` — Learning Materials
Code samples and exercises developed while following technical courses, including:
- *Windows PowerShell, Third Edition* by Ed Wilson
- *PowerShell Guide to Python* by Prateek Singh

## 🎯 Purpose

This repository serves as a personal knowledge base and toolkit, gathering reusable automation scripts for identity and infrastructure management, as well as a record of hands-on learning from PowerShell and Python courses.

## 🛠️ Requirements

Most scripts require:
- Windows PowerShell 5.1+ or PowerShell 7+
- Appropriate Active Directory / Microsoft Graph / Azure AD PowerShell modules, depending on the script
- Sufficient permissions in the target Active Directory or Entra ID tenant

## 📄 License

This repository is provided as-is for reference and educational purposes.

---

Developed and maintained by **Rafael Abel**.
