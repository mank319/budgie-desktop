/*
 * PowerIndicator.vala
 *
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class PowerIndicator : Gtk.Bin
{

    /** Current image to display */
    public Gtk.Image widget { protected set; public get; }

    /** Our upower client */
    public Up.Client client { protected set; public get; }

    /** Device references */
    protected List<unowned Up.Device> batteries;

    public PowerIndicator()
    {
        batteries = new List<Up.Device>();

        widget = new Gtk.Image();
        add(widget);

        client = new Up.Client();
        update_ui();
    }

    /**
     * Update our UI as our battery (in interest) changed/w/e
     */
    protected void update_ui()
    {
        // try to discover batteries
        var devices = client.get_devices();

        devices.foreach((device) => {
            if (device.kind != Up.DeviceKind.BATTERY) {
                return;
            }

            bool alreadyContained = false;
            batteries.foreach((battery) => {
                if (device.serial == battery.serial) alreadyContained = true;
            });

            if (!alreadyContained) {
            	batteries.append(device);
                device.notify.connect(() => update_ui ());
            }
        });
        if (batteries.length() == 0) {
            warning("Unable to discover a battery");
            remove(widget);
            hide();
            return;
        }
        hide();

        // TODO: For each battery
    	var battery = batteries.nth_data(0);

        // Got a battery, determine the icon to use
        string image_name;
        if (battery.percentage <= 10) {
            image_name = "battery-empty";
        } else if (battery.percentage <= 35) {
            image_name = "battery-low";
        } else if (battery.percentage <= 75) {
            image_name = "battery-good";
        } else {
            image_name = "battery-full";
        }

        // Fully charged OR charging
        if (battery.state == 4) {
                image_name = "battery-full-charged-symbolic";
        } else if (battery.state == 1) {
                image_name += "-charging-symbolic";
        } else {
                image_name += "-symbolic";
        }

        // Set a handy tooltip until we gain a menu in StatusApplet
        int hours = (int)battery.time_to_empty / (60 * 60);
        int minutes = (int)battery.time_to_empty / 60 - hours * 60;
        string tip = "Battery remaining: %d%% (%d:%02d)".printf((int)battery.percentage, hours, minutes);
        set_tooltip_text(tip);
        margin = 2;

        widget.set_from_icon_name(image_name, Gtk.IconSize.MENU);
        show_all();
    }
} // End class
