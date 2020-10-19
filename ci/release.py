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


def upload(name):
    print(f"Uploading {name}.tar.xz")
    filename = f"{name}-{build_date}.tar.xz"
    uploaded_url = project.upload(
        filename, filepath=f"output/{name}.tar.xz"
    )["url"]
    template = Path("Dockerfile.template").read_text()
    full_url = f"{project_url}{uploaded_url}"
    replaced = template.replace("TEMPLATE_ROOTFS_URL", full_url)
    hash = f"{Path('output/{name}.tar.xz.SHA256').read_text()[0:64]}  {filename}"
    replaced = replaced.replace(
        "TEMPLATE_ROOTFS_HASH", hash
    )
    # Remove the line containing TEMPLATE_ROOTFS_FILE
    replaced = re.sub(".*TEMPLATE_ROOTFS_FILE.*\n", "", replaced)
    return replaced, full_url


if __name__ == "__main__":
    gl = gitlab.Gitlab("https://gitlab.archlinux.org", token)
    project = gl.projects.get(project_id)

    base_replaced, base_full_url = upload("base")
    base_devel_replaced, base_devel_full_url = upload("base-devel")

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
