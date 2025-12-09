from pathlib import Path
import shutil

def get_old_new_name(session_name: str, map_old_by_new: dict, map_new_by_old: dict) -> tuple[str | None, str | None]:

    # Match old name with new name.
    old_session_name, new_session_name = None, None
    if session_name in map_new_by_old:
        old_session_name, new_session_name = session_name, map_new_by_old.get(session_name)
    elif session_name in map_old_by_new:
        old_session_name, new_session_name = map_old_by_new.get(session_name), session_name
    
    return old_session_name, new_session_name

def clean_and_rename(session: Path, old_name: str, new_name: str):
    
    # Metadata file.
    metadata_folder = Path(session, "METADATA")
    if not metadata_folder.exists():
        raise NameError("Cannot find metadata folder")
    
    for file in metadata_folder.iterdir():
        if not file.is_file(): continue
        change_pattern(file, old_name, new_name)

    # Label folder.
    label_folder = Path(session, "METADATA", "LABEL")
    if label_folder.exists():
        for file in label_folder.iterdir():
            if not file.is_file(): continue
            change_pattern(file, old_name, new_name)

    # GPS Folder.
    GPS_folder = Path(session, "GPS")
    if not GPS_folder.exists():
        raise NameError("Cannot find gps folder")
    
    for file in GPS_folder.iterdir():
        if not file.is_file(): continue
        change_pattern(file, old_name, new_name)

    
    # File at root folder.
    for file in session.iterdir():
        if not file.is_file(): continue
        change_pattern(file, old_name, new_name)


    # Rename session folder
    if session.name == old_name:
        session = session.rename(Path(session.parent, new_name))


def change_pattern(filepath: Path, old_name: str, new_name: str):
    if not filepath.is_file(): return

    if old_name in filepath.name:
        print(f"Changing name {filepath.name}")
        filepath = filepath.rename(Path(filepath.parent, filepath.name.replace(old_name, new_name)))

    if filepath.suffix.lower() not in [".csv", ".txt"]: return
    
    print(f"Update content from {filepath.name}")
    with open(filepath, "r") as f:
        lines = f.readlines()
    
    new_lines = [line.replace(old_name, new_name) for line in lines]
    with open(filepath, "w") as f:
        f.writelines(new_lines)

def remove_sql_file(session: Path):
    
    # Remove SQL file.
    print("Removing SQL file.")
    for file in session.iterdir():
        if file.suffix.lower() == ".sql":
            file.unlink()
    
    gps_folder = Path(session, "GPS")
    if not gps_folder.exists():
        print("[ERROR] GPS Folder not found")
        return

    for file in gps_folder.iterdir():
        if file.suffix.lower() == ".sql":
            file.unlink()


def move_label_folder(session: Path):

    label_folder = Path(session, "LABEL")
    metadata_folder = Path(session, "METADATA")
    metadata_folder.mkdir(exist_ok=True)
        
    
    # Move LABEL folder.
    print("Move LABEL folder in metadata folder.")
    if label_folder.exists():
        shutil.move(label_folder, Path(metadata_folder, "LABEL"))



def move_gps_content_inside_device_folder(session: Path):

    gps_path = Path(session, "GPS")
    gps_device = Path(gps_path, "DEVICE")

    if len(list(gps_path.iterdir())) == 1 and gps_device.exists(): return

    gps_device.mkdir(exist_ok=True)

    for file in gps_path.iterdir():
        if file.is_dir() and file.name == "DEVICE": continue

        shutil.move(file, Path(gps_device, file.name))