# Security

Please report vulnerabilities privately (GitHub "Report a vulnerability" under the Security tab) instead of opening a public issue.

Good to know when deploying:
- the web panel is protected by one shared access key; it is HTTPS with a self-signed certificate by default;
- the installers expose the panel to the local machine only unless you choose "local network";
- do not expose it directly to the internet without a reverse proxy and a trusted certificate;
- the `data/` folder contains the access key, the bot identity and your TeamSpeak server password: never share or commit it.
