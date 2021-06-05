#!/usr/bin/pwsh
#requires -version 7

#    Copyright (C) 2021
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

@{
    "acls"=(
        @{
            "name"="Restricted Test";
            "key"="RESTRICTED";
            "expiry"="10/10/2024";
            "permissions"=@(
                @{"HTTP_GET"=@(
                    "/api/v1/dsystem/Get*",
                    "/api/v1/idk/Get*"
                )},
                @{"HTTP_POST"=@(
                    "/api/v1/dsystem/Set*",
                    "/api/v1/idk/Set*"
                )}
            );
        },
        @{
            "name"="All Access Test";
            "key"="APIKEY";
            "expiry"="10/10/2024";
            "permissions"=@(
                @{"HTTP_GET"=@(
                    "/api/v1*"
                )},
                @{"HTTP_POST"=@(
                    "/api/v1*"
                )}
            );
        }
    )
}