local ReplicatedStorage = game:GetService("ReplicatedStorage")

for _, v in ReplicatedStorage:GetDescendants() do
	if v:IsA("RemoteFunction") then
		print(v, "RMFN")
	elseif v:IsA("RemoteEvent") then
		print(v, "RMEV")
	end
end
ReplicatedStorage:WaitForChild("UpdateDualWeapon"):InvokeServer("Gregs Will")
ReplicatedStorage:WaitForChild("RemoveItem"):InvokeServer("Gregs Will", -50)
