#!/system/bin/sh
#
# Installs every APK in /product/preinstall as an ordinary user app.
# Each one is installed once; the marker under $state keeps it from coming
# back after the user uninstalls it. KSUNManager is installed again when the
# shipped file changes, because its version follows the kernel's.

dir=/product/preinstall
state=/data/local/tmp/.axion_preinstall

mkdir -p "$state"
for apk in "$dir"/*.apk; do
    [ -f "$apk" ] || continue
    name=$(basename "$apk" .apk)
    size=$(stat -c %s "$apk")
    mark="$state/$name"
    if [ -f "$mark" ]; then
        [ "$name" = KSUNManager ] || continue
        [ "$(cat "$mark")" = "$size" ] && continue
        # a changed manager is offered once; a refused downgrade is not retried
        pm install -r -S "$size" < "$apk"
        echo "$size" > "$mark"
        continue
    fi
    # no marker yet: retried on the next boot until it succeeds
    pm install -r -S "$size" < "$apk" && echo "$size" > "$mark"
done
