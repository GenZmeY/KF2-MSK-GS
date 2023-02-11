# KF2-MSK-GS

[![Steam Workshop](https://img.shields.io/static/v1?message=workshop&logo=steam&labelColor=gray&color=blue&logoColor=white&label=steam%20)](https://steamcommunity.com/sharedfiles/filedetails/?id=2850677094)
[![GitHub](https://img.shields.io/github/license/GenZmeY/KF2-MSK-GS)](LICENSE)

# Description
Mutator providing some functions of [MSK-GS](https://steamcommunity.com/groups/msk-gs) servers.  
Contains implementations of my ideas and/or combinations of other mutators for compatibility.  
Publishing due to [the closure of the MSK-GS project](https://steamcommunity.com/groups/msk-gs/announcements/detail/3645134002744389126).  

***

**Note:** If you want to build/test/brew/publish a mutator without git-bash and/or scripts, follow [these instructions](https://tripwireinteractive.atlassian.net/wiki/spaces/KF2SW/pages/26247172/KF2+Code+Modding+How-to) instead of what is described here.

# Build
1. Install [Killing Floor 2](https://store.steampowered.com/app/232090/Killing_Floor_2/), Killing Floor 2 - SDK and [git for windows](https://git-scm.com/download/win);
2. open git-bash and go to any folder where you want to store sources:  
`cd <ANY_FOLDER_YOU_WANT>`  
3. Clone this repository and go to the source folder:  
`git clone https://github.com/GenZmeY/KF2-MSK-GS && cd KF2-MSK-GS`
4. Download dependencies:  
`git submodule init && git submodule update`  
5. Compile:  
`./tools/builder -cb`  
6. Copy server-side file:  
`C:\Users\<USERNAME>\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script\MSKGS-SRV.u`  
To your kf2 server folder: `/KFGame/BrewedPC/`  
7. Upload client-side files to steam workshop:
`./tools/builder -u`  

# Usage
See `KFMSKGS.ini` and `KFRPL.ini` configs  

# License
[GNU GPLv3](LICENSE)
