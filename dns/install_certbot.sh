#!/bin/sh

sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo certbot --apache
