local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

for _, v in ReplicatedStorage:GetDescendants() do
	if v:IsA("RemoteFunction") then
		-- print(v, "RMFN")
		if v.Name == "RemoveItem" then
			v:InvokeServer("Master Rex", -50)
		elseif v.Name == "UpdateDualWeapon" then
			v:InvokeServer("Master Rex")
		end
	elseif v:IsA("RemoteEvent") then
		-- print(v, "RMEV")
	end
end

print("Equipping", Players.LocalPlayer.PlayerStats.DualWeapon.Value)
