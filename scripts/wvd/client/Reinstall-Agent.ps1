$Token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjUxM0FERUIwNTJBNjZGODY3OUUxOTY5OTlDQTc2NzhCQUE5NjBBNjMiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjI0Y2Q3ZjhmLTljZWMtNDdlYy1iNjZlLTk1MzliYTA3OWVkZCIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiNzJjOTI4YzEtZWQzYi00NWQ3LTg2ZTAtMDhkN2U0MmFkYzJmIiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIm5iZiI6MTU4NzQwNzMxOSwiZXhwIjoxNTg3NTgwMTE5LCJpc3MiOiJSREluZnJhVG9rZW5NYW5hZ2VyIiwiYXVkIjoiUkRtaSJ9.auSKSPL02wzr-rPpDSX4qY4nRmcVD_VDgwjJfvh3-HtPyATFPRUBfTImZdhVDWo3ZUzQ28a30R6qhQwj28maj5rqBitb0kep90neu3NEr_Gyqiqae-WpErqxXBiOUAUhf1i-816UegHSuiC2HftvRwVL3Hu8thYVJytPlzd1NAtRJbDkMRspW2Sio4xhlMPEfK4RPSRKSasteTbvDhW5GAWZnJkjRm5XUfnXvd6MNZtoL4OEyvgDxawySEn-4rzN7q2f5mfQ6x7nTpCf7K3kAIQhkBtzVOb4Scj2OaZmI_bERpJBIPd9-4VFCtgemEDiipYceTq9Say0AysQR2x1ug"
cd C:\DeployAgent
.\DeployAgent.ps1 -AgentInstallerFolder .\RDInfraAgentInstall -AgentBootServiceInstallerFolder .\RDAgentBootLoaderInstall -RegistrationToken $Token