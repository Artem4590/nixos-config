{
  stdenv,
  happ-desktop,
  ...
}:

stdenv.mkDerivation {
  pname = "happ-polkit";
  version = "2.18.1";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/polkit-1/actions
    mkdir -p $out/lib/happ

    # Wrapper: запускает tun2proxy с увеличенным лимитом файловых дескрипторов.
    cat > $out/lib/happ/happ-tun2proxy-wrapper <<'EOF'
    #!/bin/sh
    ulimit -n 65536
    exec ${happ-desktop}/opt/happ/bin/tun2/tun2proxy-bin "$@"
    EOF
    chmod +x $out/lib/happ/happ-tun2proxy-wrapper

    # Helper: корректно завершает tun2proxy (SIGTERM, затем SIGKILL).
    cat > $out/lib/happ/happ-kill-tun2proxy <<'EOF'
    #!/bin/sh
    if [ $# -ne 1 ]; then
      echo "Usage: $0 <pid>" >&2
      exit 1
    fi
    PID=$1
    kill -TERM "$PID" 2>/dev/null
    sleep 2
    kill -KILL "$PID" 2>/dev/null
    exit 0
    EOF
    chmod +x $out/lib/happ/happ-kill-tun2proxy

    # Helper: корректно завершает sing-box (SIGTERM, затем SIGKILL).
    cat > $out/lib/happ/happ-kill-singbox <<'EOF'
    #!/bin/sh
    if [ $# -ne 1 ]; then
      echo "Usage: $0 <pid>" >&2
      exit 1
    fi
    PID=$1
    kill -TERM "$PID" 2>/dev/null
    sleep 2
    kill -KILL "$PID" 2>/dev/null
    exit 0
    EOF
    chmod +x $out/lib/happ/happ-kill-singbox

    # Polkit policy для tun2proxy.
    cat > $out/share/polkit-1/actions/com.happ.tun2proxy.policy <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN" "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <vendor>Happ</vendor>
      <vendor_url>https://happ.su</vendor_url>
      <action id="com.happ.tun2proxy.run">
        <description>Run tun2proxy with elevated privileges</description>
        <message>Authentication is required to run tun2proxy TUN mode</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>yes</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">$out/lib/happ/happ-tun2proxy-wrapper</annotate>
        <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
      </action>
      <action id="com.happ.tun2proxy.kill">
        <description>Kill tun2proxy process</description>
        <message>Authentication is required to stop tun2proxy TUN mode</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>yes</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/happ-kill-tun2proxy</annotate>
        <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
      </action>
    </policyconfig>
    EOF

    # Polkit policy для sing-box.
    cat > $out/share/polkit-1/actions/com.happ.singbox.policy <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN" "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <vendor>Happ</vendor>
      <vendor_url>https://happ.su</vendor_url>
      <action id="com.happ.singbox.run">
        <description>Run sing-box with elevated privileges</description>
        <message>Authentication is required to run sing-box TUN mode</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>yes</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">${happ-desktop}/opt/happ/bin/tun/sing-box</annotate>
        <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
      </action>
      <action id="com.happ.singbox.kill">
        <description>Kill sing-box process</description>
        <message>Authentication is required to stop sing-box TUN mode</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>yes</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/happ-kill-singbox</annotate>
        <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
      </action>
    </policyconfig>
    EOF

    runHook postInstall
  '';
}
