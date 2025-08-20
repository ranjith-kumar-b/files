// Main orchestration file for modular Bicep deployment
// Auto-generated from main.bicep

// === ORIGINAL PARAMETERS ===
param virtualMachines_Redis_BullMQ_Prod_VM_name string = 'Redis-BullMQ-Prod-VM'
param applicationGateways_ems_node_app_gateway_prod_name string = 'ems-node-app-gateway-prod'
param sshPublicKeys_ems_vm_key_pair_prod_name string = 'ems-vm-key-pair-prod'
param publicIPAddresses_Postgres_Prod_VM_public_ip_name string = 'Postgres-Prod-VM-public-ip'
param containerapps_ems_node_container_app_prod_name string = 'ems-node-container-app-prod'
param networkInterfaces_vm2_nic_name string = 'vm2-nic'
param userAssignedIdentities_ems_celery_worker_container_app_identity_prod_name string = 'ems-celery-worker-container-app-identity-prod'
param virtualNetworks_ems_virtual_network_prod_name string = 'ems-virtual-network-prod'
param storageAccounts_emswebappstorageaccount_name string = 'emswebappstorageaccount'
param storageAccounts_emsproductiondbackups_name string = 'emsproductiondbackups'
param storageAccounts_emsadminwebstorage_name string = 'emsadminwebstorage'
param dashboards_454c340c_51cf_4841_bce7_f0d7aee55663_name string = '454c340c-51cf-4841-bce7-f0d7aee55663'
param registries_emsnoderegistryv2prod_name string = 'emsnoderegistryv2prod'
param userAssignedIdentities_ems_node_container_app_identity_prod_name string = 'ems-node-container-app-identity-prod'
param publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name string = 'Redis-BullMQ-Prod-VM-public-ip'
param virtualMachines_Postgres_Prod_VM_name string = 'Postgres-Prod-VM'
param virtualMachines_Redis_Cache_Prod_VM_name string = 'Redis-Cache-Prod-VM'
param networkInterfaces_vm3_nic_name string = 'vm3-nic'
param networkInterfaces_Shopify_nic_name string = 'Shopify-nic'
param publicIPAddresses_ems_node_public_ip_prod_name string = 'ems-node-public-ip-prod'
param networkInterfaces_vm1_nic_name string = 'vm1-nic'
param networkSecurityGroups_vm_instances_sg_name string = 'vm-instances-sg'
param applicationGateways_ems_node_v2_app_gateway_prod_name string = 'ems-node-v2-app-gateway-prod'
param profiles_ems_webapp_cdn_profile_name string = 'ems-webapp-cdn-profile'
param networkInterfaces_vm5_nic_name string = 'vm5-nic'
param managedEnvironments_ems_node_v2_container_app_env_prod_name string = 'ems-node-v2-container-app-env-prod'
param publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name string = 'Redis-Cache-Prod-VM-public-ip'
param userAssignedIdentities_ems_celery_container_app_identity_prod_name string = 'ems-celery-container-app-identity-prod'
param virtualMachines_OpenTelemetry_Prod_VM_name string = 'OpenTelemetry-Prod-VM'
param virtualMachines_EMS_Shopify_Prod_VM_name string = 'EMS-Shopify-Prod-VM'
param publicIPAddresses_ems_node_v2_public_ip_prod_name string = 'ems-node-v2-public-ip-prod'
param containerapps_ems_node_v2_container_app_prod_name string = 'ems-node-v2-container-app-prod'
param storageAccounts_emsproductionperfdiag336_name string = 'emsproductionperfdiag336'
param registries_emsnoderegistryprod_name string = 'emsnoderegistryprod'
param publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name string = 'EMS-Shopify-Prod-VM-public-ip'
param profiles_ems_admin_webapp_cdn_profile_name string = 'ems-admin-webapp-cdn-profile'
param publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name string = 'OpenTelemetry-Prod-VM-public-ip'
param userAssignedIdentities_ems_node_v2_container_app_identity_prod_name string = 'ems-node-v2-container-app-identity-prod'
param workspaces_ems_node_log_analytics_workspace_prod_name string = 'ems-node-log-analytics-workspace-prod'
param userAssignedIdentities_ems_django_container_app_identity_prod_name string = 'ems-django-container-app-identity-prod'
param staticSites_ems_web_next_prod_name string = 'ems-web-next-prod'
param workspaces_ems_node_v2_log_analytics_workspace_prod_name string = 'ems-node--v2-log-analytics-workspace-prod'
param managedEnvironments_ems_node_container_app_env_prod_name string = 'ems-node-container-app-env-prod'

// === MODULES ===
// Deploy identity module
module identity './identity.bicep' = {
  name: 'identity-deployment'
  params: {
    userAssignedIdentities_ems_celery_worker_container_app_identity_prod_name: userAssignedIdentities_ems_celery_worker_container_app_identity_prod_name
    userAssignedIdentities_ems_node_container_app_identity_prod_name: userAssignedIdentities_ems_node_container_app_identity_prod_name
    userAssignedIdentities_ems_celery_container_app_identity_prod_name: userAssignedIdentities_ems_celery_container_app_identity_prod_name
    userAssignedIdentities_ems_node_v2_container_app_identity_prod_name: userAssignedIdentities_ems_node_v2_container_app_identity_prod_name
    userAssignedIdentities_ems_django_container_app_identity_prod_name: userAssignedIdentities_ems_django_container_app_identity_prod_name
  }
}

// Deploy networking module
module networking './networking.bicep' = {
  name: 'networking-deployment'
  params: {
    publicIPAddresses_Postgres_Prod_VM_public_ip_name: publicIPAddresses_Postgres_Prod_VM_public_ip_name
    virtualNetworks_ems_virtual_network_prod_name: virtualNetworks_ems_virtual_network_prod_name
    publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name: publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name
    publicIPAddresses_ems_node_public_ip_prod_name: publicIPAddresses_ems_node_public_ip_prod_name
    networkSecurityGroups_vm_instances_sg_name: networkSecurityGroups_vm_instances_sg_name
    publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name: publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name
    publicIPAddresses_ems_node_v2_public_ip_prod_name: publicIPAddresses_ems_node_v2_public_ip_prod_name
    publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name: publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name
    publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name: publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name
    applicationGateways_ems_node_app_gateway_prod_name_resourceId: networking-advanced.outputs.applicationGateways_ems_node_app_gateway_prod_name_resourceId
    applicationGateways_ems_node_app_gateway_prod_name_resourceName: networking-advanced.outputs.applicationGateways_ems_node_app_gateway_prod_name_resourceName
    applicationGateways_ems_node_v2_app_gateway_prod_name_resourceId: networking-advanced.outputs.applicationGateways_ems_node_v2_app_gateway_prod_name_resourceId
    applicationGateways_ems_node_v2_app_gateway_prod_name_resourceName: networking-advanced.outputs.applicationGateways_ems_node_v2_app_gateway_prod_name_resourceName
  }
  dependsOn: [
    networking-advanced
  ]
}

// Deploy networking-advanced module
module networking-advanced './networking-advanced.bicep' = {
  name: 'networking-advanced-deployment'
  params: {
    applicationGateways_ems_node_app_gateway_prod_name: applicationGateways_ems_node_app_gateway_prod_name
    networkInterfaces_vm2_nic_name: networkInterfaces_vm2_nic_name
    networkInterfaces_vm3_nic_name: networkInterfaces_vm3_nic_name
    networkInterfaces_Shopify_nic_name: networkInterfaces_Shopify_nic_name
    networkInterfaces_vm1_nic_name: networkInterfaces_vm1_nic_name
    applicationGateways_ems_node_v2_app_gateway_prod_name: applicationGateways_ems_node_v2_app_gateway_prod_name
    networkInterfaces_vm5_nic_name: networkInterfaces_vm5_nic_name
    publicIPAddresses_ems_node_public_ip_prod_name_resourceId: networking.outputs.publicIPAddresses_ems_node_public_ip_prod_name_resourceId
    publicIPAddresses_ems_node_public_ip_prod_name_resourceName: networking.outputs.publicIPAddresses_ems_node_public_ip_prod_name_resourceName
    publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name_resourceId: networking.outputs.publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name_resourceId
    publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name_resourceName: networking.outputs.publicIPAddresses_OpenTelemetry_Prod_VM_public_ip_name_resourceName
    networkSecurityGroups_vm_instances_sg_name_resourceId: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceId
    networkSecurityGroups_vm_instances_sg_name_resourceName: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceName
    networkSecurityGroups_vm_instances_sg_name_resourceId: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceId
    networkSecurityGroups_vm_instances_sg_name_resourceName: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceName
    publicIPAddresses_Postgres_Prod_VM_public_ip_name_resourceId: networking.outputs.publicIPAddresses_Postgres_Prod_VM_public_ip_name_resourceId
    publicIPAddresses_Postgres_Prod_VM_public_ip_name_resourceName: networking.outputs.publicIPAddresses_Postgres_Prod_VM_public_ip_name_resourceName
    publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name_resourceId: networking.outputs.publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name_resourceId
    publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name_resourceName: networking.outputs.publicIPAddresses_EMS_Shopify_Prod_VM_public_ip_name_resourceName
    networkSecurityGroups_vm_instances_sg_name_resourceId: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceId
    networkSecurityGroups_vm_instances_sg_name_resourceName: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceName
    networkSecurityGroups_vm_instances_sg_name_resourceId: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceId
    networkSecurityGroups_vm_instances_sg_name_resourceName: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceName
    publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name_resourceId: networking.outputs.publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name_resourceId
    publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name_resourceName: networking.outputs.publicIPAddresses_Redis_BullMQ_Prod_VM_public_ip_name_resourceName
    networkSecurityGroups_vm_instances_sg_name_resourceId: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceId
    networkSecurityGroups_vm_instances_sg_name_resourceName: networking.outputs.networkSecurityGroups_vm_instances_sg_name_resourceName
    publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name_resourceId: networking.outputs.publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name_resourceId
    publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name_resourceName: networking.outputs.publicIPAddresses_Redis_Cache_Prod_VM_public_ip_name_resourceName
    publicIPAddresses_ems_node_v2_public_ip_prod_name_resourceId: networking.outputs.publicIPAddresses_ems_node_v2_public_ip_prod_name_resourceId
    publicIPAddresses_ems_node_v2_public_ip_prod_name_resourceName: networking.outputs.publicIPAddresses_ems_node_v2_public_ip_prod_name_resourceName
  }
  dependsOn: [
    networking
  ]
}

// Deploy storage module
module storage './storage.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccounts_emswebappstorageaccount_name: storageAccounts_emswebappstorageaccount_name
    storageAccounts_emsproductiondbackups_name: storageAccounts_emsproductiondbackups_name
    storageAccounts_emsadminwebstorage_name: storageAccounts_emsadminwebstorage_name
    storageAccounts_emsproductionperfdiag336_name: storageAccounts_emsproductionperfdiag336_name
  }
}

// Deploy compute module
module compute './compute.bicep' = {
  name: 'compute-deployment'
  params: {
    virtualMachines_Redis_BullMQ_Prod_VM_name: virtualMachines_Redis_BullMQ_Prod_VM_name
    sshPublicKeys_ems_vm_key_pair_prod_name: sshPublicKeys_ems_vm_key_pair_prod_name
    virtualMachines_Postgres_Prod_VM_name: virtualMachines_Postgres_Prod_VM_name
    virtualMachines_Redis_Cache_Prod_VM_name: virtualMachines_Redis_Cache_Prod_VM_name
    virtualMachines_OpenTelemetry_Prod_VM_name: virtualMachines_OpenTelemetry_Prod_VM_name
    virtualMachines_EMS_Shopify_Prod_VM_name: virtualMachines_EMS_Shopify_Prod_VM_name
    networkInterfaces_vm3_nic_name_resourceId: networking-advanced.outputs.networkInterfaces_vm3_nic_name_resourceId
    networkInterfaces_vm3_nic_name_resourceName: networking-advanced.outputs.networkInterfaces_vm3_nic_name_resourceName
    networkInterfaces_vm5_nic_name_resourceId: networking-advanced.outputs.networkInterfaces_vm5_nic_name_resourceId
    networkInterfaces_vm5_nic_name_resourceName: networking-advanced.outputs.networkInterfaces_vm5_nic_name_resourceName
    networkInterfaces_vm2_nic_name_resourceId: networking-advanced.outputs.networkInterfaces_vm2_nic_name_resourceId
    networkInterfaces_vm2_nic_name_resourceName: networking-advanced.outputs.networkInterfaces_vm2_nic_name_resourceName
    networkInterfaces_Shopify_nic_name_resourceId: networking-advanced.outputs.networkInterfaces_Shopify_nic_name_resourceId
    networkInterfaces_Shopify_nic_name_resourceName: networking-advanced.outputs.networkInterfaces_Shopify_nic_name_resourceName
    networkInterfaces_vm1_nic_name_resourceId: networking-advanced.outputs.networkInterfaces_vm1_nic_name_resourceId
    networkInterfaces_vm1_nic_name_resourceName: networking-advanced.outputs.networkInterfaces_vm1_nic_name_resourceName
  }
  dependsOn: [
    networking-advanced
  ]
}

// Deploy containers module
module containers './containers.bicep' = {
  name: 'containers-deployment'
  params: {
    containerapps_ems_node_container_app_prod_name: containerapps_ems_node_container_app_prod_name
    registries_emsnoderegistryv2prod_name: registries_emsnoderegistryv2prod_name
    managedEnvironments_ems_node_v2_container_app_env_prod_name: managedEnvironments_ems_node_v2_container_app_env_prod_name
    containerapps_ems_node_v2_container_app_prod_name: containerapps_ems_node_v2_container_app_prod_name
    registries_emsnoderegistryprod_name: registries_emsnoderegistryprod_name
    managedEnvironments_ems_node_container_app_env_prod_name: managedEnvironments_ems_node_container_app_env_prod_name
    userAssignedIdentities_ems_node_v2_container_app_identity_prod_name_resourceId: identity.outputs.userAssignedIdentities_ems_node_v2_container_app_identity_prod_name_resourceId
    userAssignedIdentities_ems_node_v2_container_app_identity_prod_name_resourceName: identity.outputs.userAssignedIdentities_ems_node_v2_container_app_identity_prod_name_resourceName
    userAssignedIdentities_ems_node_container_app_identity_prod_name_resourceId: identity.outputs.userAssignedIdentities_ems_node_container_app_identity_prod_name_resourceId
    userAssignedIdentities_ems_node_container_app_identity_prod_name_resourceName: identity.outputs.userAssignedIdentities_ems_node_container_app_identity_prod_name_resourceName
  }
  dependsOn: [
    identity
  ]
}

// Deploy web module
module web './web.bicep' = {
  name: 'web-deployment'
  params: {
    staticSites_ems_web_next_prod_name: staticSites_ems_web_next_prod_name
  }
}

// Deploy cdn module
module cdn './cdn.bicep' = {
  name: 'cdn-deployment'
  params: {
    profiles_ems_webapp_cdn_profile_name: profiles_ems_webapp_cdn_profile_name
    profiles_ems_admin_webapp_cdn_profile_name: profiles_ems_admin_webapp_cdn_profile_name
  }
}

// Deploy monitoring module
module monitoring './monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    dashboards_454c340c_51cf_4841_bce7_f0d7aee55663_name: dashboards_454c340c_51cf_4841_bce7_f0d7aee55663_name
    workspaces_ems_node_log_analytics_workspace_prod_name: workspaces_ems_node_log_analytics_workspace_prod_name
    workspaces_ems_node_v2_log_analytics_workspace_prod_name: workspaces_ems_node_v2_log_analytics_workspace_prod_name
    applicationGateways_ems_node_app_gateway_prod_name_resourceId: networking-advanced.outputs.applicationGateways_ems_node_app_gateway_prod_name_resourceId
    applicationGateways_ems_node_app_gateway_prod_name_resourceName: networking-advanced.outputs.applicationGateways_ems_node_app_gateway_prod_name_resourceName
    applicationGateways_ems_node_v2_app_gateway_prod_name_resourceId: networking-advanced.outputs.applicationGateways_ems_node_v2_app_gateway_prod_name_resourceId
    applicationGateways_ems_node_v2_app_gateway_prod_name_resourceName: networking-advanced.outputs.applicationGateways_ems_node_v2_app_gateway_prod_name_resourceName
    profiles_ems_webapp_cdn_profile_name_resourceId: cdn.outputs.profiles_ems_webapp_cdn_profile_name_resourceId
    profiles_ems_webapp_cdn_profile_name_resourceName: cdn.outputs.profiles_ems_webapp_cdn_profile_name_resourceName
    profiles_ems_admin_webapp_cdn_profile_name_resourceId: cdn.outputs.profiles_ems_admin_webapp_cdn_profile_name_resourceId
    profiles_ems_admin_webapp_cdn_profile_name_resourceName: cdn.outputs.profiles_ems_admin_webapp_cdn_profile_name_resourceName
    virtualMachines_Redis_Cache_Prod_VM_name_resourceId: compute.outputs.virtualMachines_Redis_Cache_Prod_VM_name_resourceId
    virtualMachines_Redis_Cache_Prod_VM_name_resourceName: compute.outputs.virtualMachines_Redis_Cache_Prod_VM_name_resourceName
    virtualMachines_Redis_BullMQ_Prod_VM_name_resourceId: compute.outputs.virtualMachines_Redis_BullMQ_Prod_VM_name_resourceId
    virtualMachines_Redis_BullMQ_Prod_VM_name_resourceName: compute.outputs.virtualMachines_Redis_BullMQ_Prod_VM_name_resourceName
    virtualMachines_Postgres_Prod_VM_name_resourceId: compute.outputs.virtualMachines_Postgres_Prod_VM_name_resourceId
    virtualMachines_Postgres_Prod_VM_name_resourceName: compute.outputs.virtualMachines_Postgres_Prod_VM_name_resourceName
    containerapps_ems_node_v2_container_app_prod_name_resourceId: containers.outputs.containerapps_ems_node_v2_container_app_prod_name_resourceId
    containerapps_ems_node_v2_container_app_prod_name_resourceName: containers.outputs.containerapps_ems_node_v2_container_app_prod_name_resourceName
    containerapps_ems_node_container_app_prod_name_resourceId: containers.outputs.containerapps_ems_node_container_app_prod_name_resourceId
    containerapps_ems_node_container_app_prod_name_resourceName: containers.outputs.containerapps_ems_node_container_app_prod_name_resourceName
  }
  dependsOn: [
    networking-advanced
    cdn
    compute
    containers
  ]
}

