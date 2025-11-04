# dotfiles
My configuration for ArchLinux Hyprland
<img width="1921" height="1080" alt="image" src="https://github.com/user-attachments/assets/4dea7790-e805-4bf7-a4ae-58752c40fe76" />
<img width="1921" height="1081" alt="image" src="https://github.com/user-attachments/assets/e45a2a5f-8ef2-4e3a-9d96-cdd5521d5aaa" />
<img width="1921" height="1080" alt="image" src="https://github.com/user-attachments/assets/ec025e57-5bf7-4011-8596-e36b14a09d71" />


## 1 - Init archLinux with Hyprland

1 - boot archlinux
2 - get WIFI

```
  iwctl
  station [your_station (ex: wlan0)] connect your_ssid_wifi
```

3 - install archLinux package

```
archinstall
```

4 - Config archLinux

```
  Profile -> minimal
  package -> hyprland, sddm, kitty, fish, git, firefox, neovim, openssh
  install
  reboot
```

## 2 - Init Hyprland

```
sudo systemctl enable sddm.service
sudo systemctl start sddm.service
```

## 3 - Get my repos

1 - open a Terminal

```
Windows (or Command) + q
```

2 - create your ssh key & clone

```
mkdir ~/.ssh
cd ~/.ssh
ssh-keygen -a 100 -t ed25519
ssh -vT git@github.com

git config --global user.email "your_mail"
git config --global user.name "name"
cd
```

3 - copy your ~/.ssh/yourFile.pub in your github account

```
your profile -> ssh key -> add ssh key
```

4 - clone

```
git clone git@github.com:nassimberkhli/dotfiles.git
```

5 - install my hyprland config

```
cd dotfiles
./install.sh
```
