##########################################################
## Promote VM to be a Domain Controller
##########################################################


locals { 
import_command       = "Import-Module ADDSDeployment"
password_command     = "$password = ConvertTo-SecureString var.password -AsPlainText -Force"
install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode 7 -DomainName contoso.com -DomainNetbiosName contoso -ForestMode 7 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
exit_code_hack       = "exit 0"
powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.exit_code_hack}"
#powershell_command  = "Import-Module ADDSDeployment; $password = ConvertTo-SecureString "Password1234!" -AsPlainText -Force; Add-WindowsFeature -name ad-domain-services -IncludeManagementTools; Install-ADDSForest -CreateDnsDelegation:$false -DomainMode 7 -DomainName contoso.com -DomainNetbiosName contoso -ForestMode 7 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
}

resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  
  depends_on = [azurerm_virtual_machine.onprem-dc-vm]
  
  name                 = "create-active-directory-forest"
  virtual_machine_id   = azurerm_virtual_machine.onprem-dc-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}