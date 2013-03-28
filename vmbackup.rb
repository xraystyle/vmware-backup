#!/usr/bin/env ruby -w

# edit this path to point to the directory that contains your VMs.
@vm_dir = "</path/to/folder/containing/virtual-machines/>"

# Get a list of the VMs in the directory.
def get_vms

	Dir.chdir(@vm_dir)
	@vms = `find . -name *.vmx`.to_s
	@vms = @vms.split("\n")

end

# Check if VMs are running.
def vms_running?
	# This path applies to VMWare Fusion on OS X. You can edit it to reflect where
	# vmrun lives on your system as appropriate.
	running =`"/Applications/VMware Fusion.app/Contents/Library/vmrun" list | wc -l`.to_i
	@vm_count = running - 1
	@vm_count !=0 ? true : false
	
end

# Suspend the VMs.
def suspend_vms
	
	Dir.chdir(@vm_dir)

	@vms.each do |vm|
		# puts vm
		 `"/Applications/VMware Fusion.app/Contents/Library/vmrun" suspend '#{vm}' soft`
	end

end

# Start the VMs.
def start_vms
	
	Dir.chdir(@vm_dir)
	@vms.each do |vm|
		`"/Applications/VMware Fusion.app/Contents/Library/vmrun" start '#{vm}'`
	end

end


# -------------------------Start Script----------------------------



puts "Beginning backup of VMWare virtual machines..."

get_vms

# Check if the VMs are running. If so, suspend.

if vms_running?
	puts "Attempting to suspend VMs..."
	suspend_vms
end



if vms_running?
	puts
	puts "VMs not suspended, retrying..."
	suspend_vms
end 

if vms_running?
	puts "VMs failed to suspend, exiting..."
	# Tried to suspend twice, something went sideways. Bail.
	exit
end

if !vms_running?
	# vms suspended properly, rsync 'em.
	puts "VMs suspended successfully, beginning rsync."
	# This rsync will copy the VMs from their existing location to a specified backup folder on the same machine.
	# This can be changed to a network copy or whatever else fits your needs.
	# I rsync to a second local drive, restart the VMs, then rsync the backup drive to a remote server.
	`rsync -ah --log-file=/tmp/file.txt --delete --compress-level=0 --inplace "<Path To Virtual Machines> "<Path To Backup Location>"`
end

puts
transferred = `grep 'total size' /tmp/file.txt`
puts "From the rsync log:"
puts transferred
puts

puts "rsync finished, cleaning up stray files and restarting VMs..."

puts

`rm /tmp/file.txt`

start_vms

if !vms_running?
	puts "VMs failed to restart, retrying..."
	start_vms
end

if !vms_running?
	puts "VMs failed to restart. Exiting..."
	exit
end 
puts "VMs restarted successfully."

# I've found that Win7 VMs intermittently lose their IP address when restarted for some reason.
# This vmrun command forces IP renewal on Win7 VMs. Uncomment and edit as appropriate for your environment.
# `"/Applications//VMware Fusion.app/Contents/Library/vmrun" -gu <vm username> -gp <vm password> runScriptInGuest "</path/to/guest>" "" "ipconfig /renew"`
# Note the empty quotes after the path to the guest VM. These are necessary to get Cmd.exe to execute the script.

puts
puts "Backup completed successfully."




