for _, v in game.ReplicatedStorage:GetDescendants() do
	if v:IsA("RemoteFunction") then
		print(v, "RMFN")
	elseif v:IsA("RemoteEvent") then
		print(v, "RMEV")
	end
end
game.ReplicatedStorage:WaitForChild("UpdateDualWeapon"):InvokeServer("Gregs Will")
game.ReplicatedStorage:WaitForChild("RemoveItem"):InvokeServer("Gregs Will", -50)
