/*
 *    AddContactDialog.vala
 *
 *    Copyright (C) 2013-2014  Venom authors and contributors
 *
 *    This file is part of Venom.
 *
 *    Venom is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Venom is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Venom.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Venom {
  public class AddContactDialog : Gtk.Dialog{
    public string id {
      get { return entry_contact_id.text; }
      set { entry_contact_id.text = value; }
    }
    public string message {
      owned get { return textview_contact_message.buffer.text; }
      set { textview_contact_message.buffer.text = value; }
    }
    public int max_message_length { get; set; default = -1;}

    private Gtk.Entry entry_contact_id;
    private Gtk.TextView textview_contact_message;

    private GLib.Regex id_regex;

    public AddContactDialog() {
      init_widgets();
    }

    private void init_widgets() {
      Gtk.Builder builder = new Gtk.Builder();
      try {
        builder.add_from_resource("/org/gtk/venom/add_contact_dialog.ui");
      } catch (GLib.Error e) {
        stderr.printf("Loading add contact window failed!\n");
      }

      Gtk.Box box = builder.get_object("box") as Gtk.Box;
      this.get_content_area().add(box);

      entry_contact_id = builder.get_object("entry_contact_id") as Gtk.Entry;
      textview_contact_message = builder.get_object("textview_contact_message") as Gtk.TextView;
      entry_contact_id.icon_release.connect(on_entry_icon_release);
      entry_contact_id.changed.connect(on_entry_changed);

      on_entry_changed();

      textview_contact_message.buffer.insert_text.connect(on_insert_text);

      try {
        id_regex = new GLib.Regex("^[[:xdigit:]]*$");
      } catch (RegexError re) {
        stderr.printf("Failed to compile regex: %s\n", re.message);
      }

      this.add_buttons("_Cancel", Gtk.ResponseType.CANCEL, "_Ok", Gtk.ResponseType.OK, null);
      this.set_default_response(Gtk.ResponseType.OK);
      this.title = "Add contact";
      this.set_default_size(400, 250);
    }

    private string? open_get_pin_dialog() {
      string pin = null;
      PinDialog dialog = new PinDialog();
      dialog.transient_for = this;
      dialog.modal = true;
      dialog.show_all();

      int result = dialog.run();
      if(result == Gtk.ResponseType.OK) {
        pin = dialog.pin;
      }
      dialog.destroy();
      return pin;
    }

    private void on_entry_icon_release(Gtk.EntryIconPosition p0, Gdk.Event p1) {
      resolve_tox_id();
    }

    private void resolve_tox_id() {
      ToxDns dns_resolver = new ToxDns();
      string resolved_id = dns_resolver.resolve_id(Tools.remove_whitespace(id), open_get_pin_dialog);
      if(resolved_id != null) {
        id = resolved_id;
      } else {
        UITools.ErrorDialog("Could not resolve ID from DNS record");
      }
    }

    private void on_insert_text(ref Gtk.TextIter pos, string new_text, int new_text_length) {
      int buffer_length = textview_contact_message.buffer.text.length;
      if(max_message_length < 0 || buffer_length <= max_message_length)
        return;

      //TODO cut off too long messages
    }

    private void on_entry_changed() {
      if(id == null || id == "") {
        entry_contact_id.secondary_icon_tooltip_text = "No ID given";
        entry_contact_id.secondary_icon_name = "emblem-important-symbolic";
        entry_contact_id.secondary_icon_sensitive = false;
      } else {
        string stripped_id = Tools.remove_whitespace(id);
        if (ToxDns.tox_uri_regex != null && ToxDns.tox_uri_regex.match(stripped_id)) {
          entry_contact_id.secondary_icon_tooltip_text = "Resolve ID...";
          entry_contact_id.secondary_icon_name = "emblem-synchronizing-symbolic";
          entry_contact_id.secondary_icon_sensitive = true;
        } else if (stripped_id.length != Tox.FRIEND_ADDRESS_SIZE*2) {
          entry_contact_id.secondary_icon_tooltip_text = "ID of invalid size";
          entry_contact_id.secondary_icon_name = "emblem-important-symbolic";
          entry_contact_id.secondary_icon_sensitive = false;
        } else if (id_regex != null && !id_regex.match(stripped_id)) {
          entry_contact_id.secondary_icon_tooltip_text = "ID contains invalid characters";
          entry_contact_id.secondary_icon_name = "emblem-important-symbolic";
          entry_contact_id.secondary_icon_sensitive = false;
        } else {
          entry_contact_id.secondary_icon_name = "emblem-ok-symbolic";
          entry_contact_id.secondary_icon_tooltip_text = "Valid ID";
          entry_contact_id.secondary_icon_sensitive = false;
        }
      }
    }
  }
}
