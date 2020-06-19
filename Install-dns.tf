##########################################################
## Create AD Forest and Onprem Domain Controller
##########################################################


locals { 
#import_command       = "Import-Module ADDSDeployment"
#password_command     = "$password = ConvertTo-SecureString var.password -AsPlainText -Force"
#install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
#configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode 7 -DomainName contoso.com -DomainNetbiosName contoso -ForestMode 7 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
#exit_code_hack       = "exit 0"
#powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

resource "azurerm_virtual_machine_extension" "install-dns-onprem-dc" {
    
  name                 = "install-dns-onprem-dc"
  virtual_machine_id   = azurerm_virtual_machine.onprem-dns-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools; exit 0"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "install-dns-az-dc" {
    
  name                 = "install-dns-az-dc"
  virtual_machine_id   = azurerm_virtual_machine.az-dns-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools; exit 0"
    }
SETTINGS
}