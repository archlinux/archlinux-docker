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
    base_uploaded_url = project.upload(
        f"base-{build_date}.tar.xz", filepath="base.tar.xz"
    )["url"]
    base_template = Path("Dockerfile.template").read_text()
    base_full_url = f"{project_url}{base_uploaded_url}"
    base_replaced = base_template.replace("TEMPLATE_LOCATION_HERE", base_full_url)

    print("Uploading base-devel.tar.xz")
    base_devel_uploaded_url = project.upload(
        f"base-devel-{build_date}.tar.xz", filepath="base-devel.tar.xz"
    )["url"]
    base_devel_template = Path("Dockerfile.template").read_text()
    base_devel_full_url = f"{project_url}{base_devel_uploaded_url}"
    base_devel_replaced = base_devel_template.replace(
        "TEMPLATE_LOCATION_HERE", base_devel_full_url
    )

    print("Templating Dockerfiles")
    data = {
        "branch": "add-base-devel-tags",
        "commit_message": f"Release {build_date}",
        "actions": [
            {
                "action": "update",
                "file_path": "base/Dockerfile",
                "content": base_replaced,
            },
            {
                "action": "update",
                "file_path": "base-devel/Dockerfile",
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
