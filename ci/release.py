#!/usr/bin/env python

"""
Should only be called from GitLab CI!

Required env vars:
 - GITLAB_PROJECT_TOKEN
 - BUILD_DATE
 - CI_PROJECT_ID
 - CI_PROJECT_URL
"""

import os
import re
from pathlib import Path
import gitlab

token = os.environ['GITLAB_PROJECT_TOKEN']
build_date = os.environ['BUILD_DATE']
project_id = os.environ['CI_PROJECT_ID']
project_url = os.environ['CI_PROJECT_URL']

if __name__ == "__main__":
    gl = gitlab.Gitlab("https://gitlab.archlinux.org", token)
    project = gl.projects.get(project_id)

    print("Uploading base.tar.xz")
    base_filename = f"base-{build_date}.tar.xz"
    base_uploaded_url = project.upload(
        base_filename, filepath="base.tar.xz"
    )["url"]
    base_template = Path("Dockerfile.template").read_text()
    base_full_url = f"{project_url}{base_uploaded_url}"
    base_replaced = base_template.replace("TEMPLATE_ROOTFS_URL", base_full_url)
    base_hash = f"{Path('base.tar.xz.SHA256').read_text()[0:64]}  {base_filename}"
    base_replaced = base_replaced.replace(
        "TEMPLATE_ROOTFS_HASH", base_hash
    )
    # Remove the line containing TEMPLATE_ROOTFS_FILE
    base_replaced = re.sub(".*TEMPLATE_ROOTFS_FILE.*\n", "", base_replaced)

    print("Uploading base-devel.tar.xz")
    base_devel_filename = f"base-devel-{build_date}.tar.xz"
    base_devel_uploaded_url = project.upload(
        base_devel_filename, filepath="base-devel.tar.xz"
    )["url"]
    base_devel_template = Path("Dockerfile.template").read_text()
    base_devel_full_url = f"{project_url}{base_devel_uploaded_url}"
    base_devel_replaced = base_devel_template.replace(
        "TEMPLATE_ROOTFS_URL", base_devel_full_url
    )
    base_devel_hash = f"{Path('base-devel.tar.xz.SHA256').read_text()[0:64]}  {base_devel_filename}"
    base_devel_replaced = base_devel_replaced.replace(
        "TEMPLATE_ROOTFS_HASH", base_devel_hash
    )
    # Remove the line containing TEMPLATE_ROOTFS_FILE
    base_devel_replaced = re.sub(".*TEMPLATE_ROOTFS_FILE.*\n", "", base_devel_replaced)

    print("Templating Dockerfiles")
    data = {
        "branch": "add-base-devel-tags",
        "commit_message": f"Release {build_date}",
        "actions": [
            {
                "action": "update",
                "file_path": "ci/base/Dockerfile",
                "content": base_replaced,
            },
            {
                "action": "update",
                "file_path": "ci/base-devel/Dockerfile",
                "content": base_devel_replaced,
            },
        ],
    }
    project.commits.create(data)

    print("Creating release")
    release = project.releases.create(
        {
            "name": f"Release {build_date}",
            "tag_name": build_date,
            "description": f"Release {build_date}",
            "ref": "add-base-devel-tags",
            "assets": {
                "links": [
                    {
                        "name": "base.tar.xz",
                        "url": base_full_url,
                        "link_type": "package",
                    },
                    {
                        "name": "base-devel.tar.xz",
                        "url": base_devel_full_url,
                        "link_type": "package",
                    }
                ]
            },
        }
    )
    print("Created release", release.get_id())
