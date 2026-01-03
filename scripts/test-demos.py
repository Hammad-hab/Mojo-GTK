import os
import subprocess
import signal

demos = os.listdir('gtk-demos/')

processess = subprocess.run(['ps'], capture_output=True)
isPixiRunning = ("pixi" in processess.stdout.decode('utf-8'))
if not isPixiRunning:
    raise RuntimeError('Pixi shell is not active. Please run this script after activating pixi')


summary = []  # (demo, errors, warnings, build_ok)

for demo in demos:
    if not demo.endswith(".mojo") or demo == "gtk.mojo":
        continue

    output = subprocess.run(
        ["mojo", "build", os.path.join("gtk-demos", demo)],
        capture_output=True
    )

    stderr = output.stderr.decode('utf-8')
    lines = stderr.split('\n')

    errored_lines = [l for l in lines if "error:" in l.lower()]
    warning_lines = [l for l in lines if "warning" in l.lower()]

    errors = len(errored_lines)
    warnings = len(warning_lines)
    build_ok = (output.returncode == 0)

    print(errors, "errors produced in file", demo)
    print(warnings, "warnings produced in file", demo)

    if errors <= 0:      
        exe = demo.replace('.mojo', "")
        proc = subprocess.Popen([f'./{exe}'])
        proc.terminate()
        output = proc.wait()
        try:
            os.remove(exe)
        except:
            print('Failed to delete executable of', demo)
        
        summary.append((demo, errors, warnings, build_ok, output))
    else:
        summary.append((demo, errors, warnings, build_ok, 0))
    


# ---- Summary table ----
print("\nBuild Summary")
print("-" * 80)
print(f"{'File':30} {'Errors':>8} {'Warnings':>10} {'Status':>10} {'Retcode':>10}")
print("-" * 80)

total_errors = 0
total_warnings = 0

for demo, errors, warnings, build_ok, retcode in summary:
    status = "OK" if build_ok else "FAIL"
    total_errors += errors
    total_warnings += warnings
    print(f"{demo:30} {errors:8d} {warnings:10d} {status:>10} {(retcode):>10d}")

print("-" * 80)
print(f"{'TOTAL':30} {total_errors:8d} {total_warnings:10d}")
