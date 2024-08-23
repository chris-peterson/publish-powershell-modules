FROM mcr.microsoft.com/dotnet/sdk:9.0

COPY 'entrypoint.ps1' '/'

ENTRYPOINT [ "/entrypoint.ps1" ]
