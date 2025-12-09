import pandas as pd
from io import BytesIO
import base64
from enum import Enum
from pathlib import Path
from PIL import Image
import exiftool
import json

class MetadataStatus(Enum):
    NOT_FOUND = "not-found"
    EMPTY = "empty"
    GEOMETRY_FAILED = "geometry_failed"
    GOOD = "good"


def get_metadata_file_status(session: Path) -> MetadataStatus:

    metadata_path = Path(session, "METADATA", "metadata.csv")

    if not metadata_path.exists(): return MetadataStatus.NOT_FOUND

    metadata_df = pd.read_csv(metadata_path)

    if metadata_df.empty: return MetadataStatus.EMPTY

    if "geometry" in metadata_df: return MetadataStatus.GEOMETRY_FAILED

    return MetadataStatus.GOOD



def format_metadata_file(session: Path):

    metadata_status = get_metadata_file_status(session)

    if metadata_status in [MetadataStatus.EMPTY, MetadataStatus.NOT_FOUND]:
        format_metadata_file_empty_not_found(session)
    elif metadata_status == MetadataStatus.GEOMETRY_FAILED:
        format_metadata_file_geometry_failed(session)
    else:
        format_metadata_file_good(session)



def format_metadata_file_good(session: Path):

    metadata_folder = Path(session, "METADATA")
    metadata_file = Path(metadata_folder, "metadata.csv")

    metadata_df = pd.read_csv(metadata_file)

    if "GPSMapDatum" not in metadata_df:
        metadata_df["GPSMapDatum"] = "WGS-84"

    if "photo_id" in metadata_df:
        metadata_df.drop("photo_id", axis=1, inplace=True)
    
    if "photo_identifier" in metadata_df:
        metadata_df.rename(columns={"FileName":"OriginalFileName"}, inplace=True)
        metadata_df.rename(columns={"photo_identifier":"FileName"}, inplace=True)

    if "GPSLatitude_native" in metadata_df and "GPSLatitude" in metadata_df:
        metadata_df.drop("GPSLatitude_native", axis=1, inplace=True)
    elif "GPSLatitude_native" in metadata_df and "GPSLatitude" not in metadata_df:
        metadata_df.rename(columns={"GPSLatitude_native":"GPSLatitude"}, inplace=True)

    if "GPSLongitude_native" in metadata_df and "GPSLongitude" in metadata_df:
        metadata_df.drop("GPSLongitude_native", axis=1, inplace=True)
    elif "GPSLongitude_native" in metadata_df and "GPSLongitude" not in metadata_df:
        metadata_df.rename(columns={"GPSLongitude_native":"GPSLongitude"}, inplace=True)

    if "ThumbnailImage" not in metadata_df:
        metadata_df["ThumbnailImage"] = metadata_df.apply(lambda row: create_thumbnail(session, row), axis=1)
    
    if list(metadata_df) != sorted(metadata_df.columns):
        metadata_df = metadata_df.reindex(sorted(metadata_df.columns), axis=1)
    
    metadata_df.to_csv(metadata_file, index=False)



def format_metadata_file_geometry_failed(session: Path):

    metadata_folder = Path(session, "METADATA")
    metadata_file = Path(metadata_folder, "metadata.csv")

    with open(metadata_file, "r") as f:
        lines = f.readlines()
    
    if '"geometry"' in lines[0]:
        lines[0] = lines[0].replace('"geometry"', '"GPSLongitude","GPSLatitude"')

    with open(metadata_file, "w") as f:
        f.writelines(lines)
    
    metadata_df = pd.read_csv(metadata_file)

    if metadata_df["GPSLatitude"].dtype == "object":
        metadata_df["GPSLatitude"] = metadata_df["GPSLatitude"].apply(lambda row: row.replace("c(", "").replace(")", ""))
    
    if metadata_df["GPSLongitude"].dtype == "object":
        metadata_df["GPSLongitude"] = metadata_df["GPSLongitude"].apply(lambda row: row.replace("c(", "").replace(")", ""))
    
    if "GPSMapDatum" not in metadata_df:
        metadata_df["GPSMapDatum"] = "WGS-84"

    if "photo_id" in metadata_df:
        metadata_df.drop("photo_id", axis=1, inplace=True)
    
    metadata_df.rename(columns={"FileName":"OriginalFileName"}, inplace=True)
    metadata_df.rename(columns={"photo_identifier":"FileName"}, inplace=True)

    if "GPSLatitude_native" in metadata_df and "GPSLatitude" in metadata_df:
        metadata_df.drop("GPSLatitude_native", axis=1, inplace=True)
    elif "GPSLatitude_native" in metadata_df and "GPSLatitude" not in metadata_df:
        metadata_df.rename(columns={"GPSLatitude_native":"GPSLatitude"}, inplace=True)

    if "GPSLongitude_native" in metadata_df and "GPSLongitude" in metadata_df:
        metadata_df.drop("GPSLongitude_native", axis=1, inplace=True)
    elif "GPSLongitude_native" in metadata_df and "GPSLongitude" not in metadata_df:
        metadata_df.rename(columns={"GPSLongitude_native":"GPSLongitude"}, inplace=True)

    metadata_df["ThumbnailImage"] = metadata_df.apply(lambda row: create_thumbnail(session, row), axis=1)
    
    if list(metadata_df) != sorted(metadata_df.columns):
        metadata_df = metadata_df.reindex(sorted(metadata_df.columns), axis=1)
    metadata_df.to_csv(metadata_file, index=False)


def format_metadata_file_empty_not_found(session: Path):

    metadata_folder = Path(session, "METADATA")
    metadata_folder.mkdir(exist_ok=True)
    metadata_file = Path(metadata_folder, "metadata.csv")

    dcim_folder = Path(session, "DCIM")

    if not dcim_folder.exists():
        raise NameError("DCIM folder not found, cannot extract metadata")
    
    metadata_df = pd.DataFrame()
    for folder in dcim_folder.iterdir():
        if "GOPR" not in folder.name or not folder.is_dir(): continue
        print(f"Extracting metadata from {folder}")

        # Get metadata of frames
        with exiftool.ExifTool(common_args=["-n", "-a"]) as et:
            json_frames_metadata = et.execute(*[f"-j", "-fileorder", "filename", str(folder)])

        csv_exiftool_frames = pd.DataFrame.from_dict(json.loads(json_frames_metadata))

        columns_to_keep = ['SourceFile', 'photo_id', 'photo_identifier', 'session_id', 'photo_relative_file_path', 'session_photo_number', 'ApertureValue', 'Compression', 'Contrast', 'CreateDate', 'DateTimeOriginal', 'DigitalZoomRatio', 'ExifImageHeight', 'ExifImageWidth', 'ExifToolVersion', 'ExifVersion', 'ExposureCompensation', 'ExposureMode', 'ExposureProgram', 'FileName', 'FileSize', 'FileType', 'FileTypeExtension', 'FNumber', 'FocalLength', 'FocalLength35efl', 'FocalLengthIn35mmFormat', 'FOV', 'GPSAltitude', 'GPSAltitudeRef', 'GPSDateTime', 'GPSLatitude_native', 'GPSLatitudeRef', 'GPSLongitude_native', 'GPSLongitudeRef', 'GPSPosition', 'GPSTimeStamp', 'ImageHeight', 'ImageWidth', 'LightValue', 'Make', 'MaxApertureValue', 'Megapixels', 'MeteringMode', 'MIMEType', 'Model', 'Saturation', 'ScaleFactor35efl', 'SceneCaptureType', 'SceneType', 'SensingMethod', 'Sharpness', 'ShutterSpeed', 'Software', 'ThumbnailLength', 'ThumbnailOffset', 'WhiteBalance', 'XResolution', 'YResolution', 'geometry']
        csv_exiftool_head = list(csv_exiftool_frames)

        ctk = list(set(columns_to_keep) & set(csv_exiftool_head))

        csv_exiftool_frames = csv_exiftool_frames[ctk]
        metadata_df = pd.concat([metadata_df, csv_exiftool_frames])
    

    if "GPSMapDatum" not in metadata_df:
        metadata_df["GPSMapDatum"] = "WGS-84"

    if "GPSPosition" in metadata_df and ("GPSLatitude" not in metadata_df or "GPSLongitude" not in metadata_df):
        metadata_df["GPSLatitude"] = metadata_df["GPSPosition"].apply(lambda p: str(p).split(' ')[0] if type(p) == str else "")
        metadata_df["GPSLongitude"] = metadata_df["GPSPosition"].apply(lambda p: str(p).split(' ')[1] if type(p) == str else "")

    metadata_df["FileName"] = metadata_df.apply(lambda row: f"{session.name}_{row['SourceFile'].split('/')[-1]}", axis=1)
    metadata_df["OriginalFileName"] = metadata_df.apply(lambda row: f"{row['SourceFile'].split('/')[-1]}", axis=1)


    def get_relative_file_path(session_name, row) -> str:

        right_part = row["SourceFile"].split(session_name)[1]
        return f"/{session_name}{right_part}"

    metadata_df["photo_relative_file_path"] = metadata_df.apply(lambda row: get_relative_file_path(session.name, row), axis=1)
    metadata_df["ThumbnailImage"] = metadata_df.apply(lambda row: create_thumbnail(session, row), axis=1)

    metadata_df.drop(columns=["SourceFile"], inplace=True)
    if list(metadata_df) != sorted(metadata_df.columns):
        metadata_df = metadata_df.reindex(sorted(metadata_df.columns), axis=1)
    metadata_df.to_csv(metadata_file, index=False)


def create_thumbnail(session: Path, row: pd.Series):
    
    img_path = Path(session.parent, row["photo_relative_file_path"][1:])
    
    # --- Open image and create thumbnail ---
    with Image.open(img_path) as img:

        img.thumbnail((128,128))  # adjust size as needed

        # Save thumbnail to a buffer
        buffer = BytesIO()
        img.save(buffer, format="JPEG")
        buffer.seek(0)

        # Encode to base64
        img_base64 = base64.b64encode(buffer.read()).decode("utf-8")
        img_base64 = f"base64:{img_base64}"
    
    return img_base64