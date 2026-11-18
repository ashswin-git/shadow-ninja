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

    if os.environ.get('JAVA_HOME'):
        os.environ['PATH'] = f"{os.environ['JAVA_HOME']}/bin:" + os.environ['PATH']

    gradle_args = [
        './gradlew',
        'bundleRelease',
        'assembleRelease',
        '-Pperform_signing=true',
        f'-Prelease_keystore_file={store_file}',
        f'-Prelease_keystore_password={store_pass}',
        f'-Prelease_keystore_alias={key_alias}',
        '-Pperform_zipalign=true',
        '-Pexport_package_name=com.ashswin.shadowninja',
        '-Pexport_version_code=1',
        '-Pexport_version_name=1.0.0',
        '-Pexport_version_min_sdk=24',
        '-Pexport_version_target_sdk=35'
    ]

    print('Running Gradle build with signing...')
    res = subprocess.run(gradle_args, cwd='android')
    if res.returncode != 0:
        print('Gradle build failed!')
        exit(1)
    print('Gradle build succeeded!')

    # Find built APK
    apk_path = 'android/build/outputs/apk/release/android-release.apk'
    if not os.path.exists(apk_path):
        # Search for any apk in android/build
        for root, dirs, files in os.walk('android/build'):
            for file in files:
                if file.endswith('.apk'):
                    apk_path = os.path.join(root, file)
                    break

    if os.path.exists(apk_path):
        os.makedirs('dist', exist_ok=True)
        final_apk = 'dist/ShadowNinja-1.0.0.apk'
        prev_apk = 'dist/ShadowNinja-1.0.0.prev.apk'

        if os.path.exists(final_apk):
            if os.path.exists(prev_apk):
                os.remove(prev_apk)
            shutil.copy2(final_apk, prev_apk)
            print(f'Backed up existing APK to {prev_apk}')

        shutil.copy2(apk_path, final_apk)
        print(f'Copied new APK to {final_apk}')
        print(f'APK SHA256: {get_sha256(final_apk)}')

        apksigner_path = os.environ.get('APKSIGNER', 'apksigner')
        if os.path.exists(apksigner_path):
            print('Running apksigner verify...')
            subprocess.run([apksigner_path, 'verify', '--verbose', final_apk])

    # Copy ui-mockups and reference
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
