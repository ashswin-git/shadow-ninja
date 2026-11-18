import os
import subprocess
import hashlib
import shutil

def get_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def main():
    # 1. Read keystore.properties
    props = {}
    prop_path = 'keystore/keystore.properties'
    if os.path.exists(prop_path):
        with open(prop_path, 'r') as f:
            for line in f:
                if '=' in line:
                    k, v = line.strip().split('=', 1)
                    props[k] = v

    store_pass = props.get('storePassword', '')
    key_alias = props.get('keyAlias', 'upload')
    store_file = props.get('storeFile', 'keystore/upload.jks')

    # 2. Update export_presets.cfg with release signing and com.ashswin.shadowninja
    preset_path = 'export_presets.cfg'
    with open(preset_path, 'r') as f:
        content = f.read()

    import re
    content = re.sub(r'package/unique_name=".*?"', 'package/unique_name="com.ashswin.shadowninja"', content)
    content = re.sub(r'package/name=".*?"', 'package/name="Aether Shinobi: Spirit Blade"', content)
    content = re.sub(r'codesign/release/keystore=.*?\n', f'codesign/release/keystore="{store_file}"\n', content)
    content = re.sub(r'codesign/release/user=.*?\n', f'codesign/release/user="{key_alias}"\n', content)
    content = re.sub(r'codesign/release/pass=.*?\n', f'codesign/release/pass="{store_pass}"\n', content)

    with open(preset_path, 'w') as f:
        f.write(content)

    os.makedirs('dist', exist_ok=True)
    os.makedirs('build', exist_ok=True)

    godot_bin = os.environ.get('GODOT', 'godot')
    project_path = '.'

    apk_out_local = 'build/ShadowNinja-1.0.0.apk'
    final_apk = 'dist/ShadowNinja-1.0.0.apk'
    prev_apk = 'dist/ShadowNinja-1.0.0.prev.apk'

    print(f'Exporting APK to {apk_out_local}...')
    res_apk = subprocess.run([godot_bin, '--path', project_path, '--headless', '--export-release', 'Android', apk_out_local])

    if res_apk.returncode != 0:
        print('APK export failed!')
        return

    if os.path.exists(final_apk):
        if os.path.exists(prev_apk):
            os.remove(prev_apk)
        shutil.copy2(final_apk, prev_apk)
        print(f'Backed up existing APK to {prev_apk}')

    shutil.copy2(apk_out_local, final_apk)
    print(f'Copied new APK to {final_apk}')

    if os.path.exists(final_apk):
        print(f'APK SHA256: {get_sha256(final_apk)}')
        apksigner_path = os.environ.get('APKSIGNER', 'apksigner')
        if os.path.exists(apksigner_path):
            print('Running apksigner verify...')
            subprocess.run([apksigner_path, 'verify', '--verbose', final_apk])

    # 3. Copy ui-mockups and reference to original workspace
    os.makedirs('ui-mockups', exist_ok=True)
    os.makedirs('reference', exist_ok=True)

    if os.path.exists('ui-mockups'):
        for f in os.listdir('ui-mockups'):
            src = os.path.join('ui-mockups', f)
            if os.path.isfile(src):
                shutil.copy2(src, os.path.join('ui-mockups', f))
    if os.path.exists('reference'):
        for root, dirs, files in os.walk('reference'):
            rel = os.path.relpath(root, 'reference')
            dest_dir = os.path.join('reference', rel)
            os.makedirs(dest_dir, exist_ok=True)
            for file in files:
                shutil.copy2(os.path.join(root, file), os.path.join(dest_dir, file))
    print('Copied mockups and reference files to the project root.')

if __name__ == '__main__':
    main()
