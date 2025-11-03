import pandas as pd
from pathlib import Path
import traceback

from src.clean_and_rename import get_old_new_name, clean_and_rename, remove_sql_file, move_label_folder, move_gps_content_inside_device_folder
from src.metadata import format_metadata_file

ROOT_FOLDER = Path("./sessions/")


def main():

    conversion_old_new_df = pd.read_csv("./csv/conversion_old_new_session_name.csv")
    map_old_by_new = {row["new_session_name"]:row["old_session_name"] for i, row in conversion_old_new_df.iterrows()}
    map_new_by_old = {row["old_session_name"]:row["new_session_name"] for i, row in conversion_old_new_df.iterrows()}



    for session in sorted(list(ROOT_FOLDER.iterdir())):

        try:

            old_session_name, new_session_name = get_old_new_name(session.name, map_old_by_new, map_new_by_old)
            if old_session_name == None and new_session_name == None:
                print("Session not found in mapping")
                continue

            print(f"\n\nWorking with {session.name}")
            print(f"Old name: {old_session_name}, New name: {new_session_name}")

            # Make metadata file clean
            format_metadata_file(session)

            remove_sql_file(session)

            move_label_folder(session)

            # Move all gps file inside a DEVICE folder.
            move_gps_content_inside_device_folder(session)

            # Delete, move and rename file and folder
            clean_and_rename(session, old_session_name, new_session_name)

            
        except Exception:
            # Print error
            print(traceback.format_exc(), end="\n\n")


if __name__ == "__main__":
    main()