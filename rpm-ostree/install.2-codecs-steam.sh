#!/bin/sh
# Needs install.1.sh to have been run first.
set -e

# See <https://rpmfusion.org/Howto/OSTree?highlight=%28%5CbCategoryHowto%5Cb%29#Major_releases>.
sudo rpm-ostree update \
    --uninstall rpmfusion-free-release \
    --uninstall rpmfusion-nonfree-release \
    --install rpmfusion-free-release \
    --install rpmfusion-nonfree-release

# See <https://rpmfusion.org/Howto/OSTree?highlight=%28%5CbCategoryHowto%5Cb%29#Software_codecs>.
sudo rpm-ostree install \
	gstreamer1-plugins-bad-free-extras \
	gstreamer1-plugins-bad-freeworld \
	gstreamer1-plugins-ugly \
	gstreamer1-vaapi \
	pipewire-codec-aptx \
	steam

rpm-ostree override remove \
	ffmpeg-free \
	libavcodec-free \
	libavdevice-free \
	libavfilter-free \
	libavformat-free \
	libavutil-free \
	libpostproc-free \
	libswresample-free \
	libswscale-free \
	noopenh264 \
	--install ffmpeg
