-- 肉鸽模拟经营场景3D节点
local XRogueSimGrid3D = XClass(nil, "XRogueSimGrid3D")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local layerUiNear = 24

function XRogueSimGrid3D:Ctor(scene, grid)
	self.Scene = scene
	self.Grid = grid
	self._Control = self.Scene._MainControl
	self.IsLoaded = false -- 是否已加载
end

-- 加载
function XRogueSimGrid3D:Load()
    local gridGo = CSInstantiate(self.Scene.SceneGrid, self.Scene.SceneGridList)
	self.Transform = gridGo.transform
	self.GameObject = gridGo.gameObject
    self.GameObject:SetActiveEx(true)
	self.IsLoaded = true

    self.Transform.name = tostring(self.Grid.Id)
    self.Transform.position = self.Scene:GetWorldPosByGridId(self.Grid.Id)
	self:OnLoaded()
end

function XRogueSimGrid3D:OnLoaded()
	self.TerrainLink = XUiHelper.TryGetComponent(self.Transform, "TerrainLink")
	self.LandformLink = XUiHelper.TryGetComponent(self.Transform, "LandformLink")
	self.UiGridCanvasLink = XUiHelper.TryGetComponent(self.Transform, "UiGridCanvasLink")
	self.CloudLink = XUiHelper.TryGetComponent(self.Transform, "CloudLink")
	self.ExploredEffectLink = XUiHelper.TryGetComponent(self.Transform, "ExploredEffectLink")
	
	self:RefreshTerrain()
	self:RefreshLandform()

	local isBlock = self.Grid:GetIsBlock()
	if isBlock then
		self:LoadCloud()
	end

	if not self.Grid:GetCanExplore() then
		self:Darken()
	end
end

function XRogueSimGrid3D:Release()
	self.Scene = nil
	self.Grid = nil
	self._Control = nil
	self.Transform = nil
	self.GameObject = nil
	self.TerrainLink = nil
	self.LandformLink = nil
	self.UiGridCanvasLink = nil
	self.CloudLink = nil
	self.ExploredEffectLink = nil
	self.TerrainMeshRenderer = nil
	self.LandformMeshRenderer = nil
	self.CloudMeshRenderer = nil
end

function XRogueSimGrid3D:Refresh()
	self:RefreshLandformShow()
end

function XRogueSimGrid3D:Show(isShow)
	if not self.IsLoaded then
		return
	end

	self.GameObject:SetActiveEx(isShow)
end

-- 更新地形
function XRogueSimGrid3D:RefreshTerrain()
	if not self.IsLoaded then
		return
	end

	if self.Grid.TerrainId == 0 then
		self.TerrainLink.gameObject:SetActiveEx(false)
		return
	end

	local terrainCfg = self._Control.MapSubControl:GetRogueSimTerrainConfig(self.Grid.TerrainId)
	if terrainCfg.Model == nil then
		self.TerrainLink.gameObject:SetActiveEx(false)
		return
	end

	self.TerrainLink.gameObject:SetActiveEx(true)
	local go = self.TerrainLink.gameObject:LoadPrefab(terrainCfg.Model)
	self.TerrainMeshRenderer = go:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))
end

-- 更新地貌
function XRogueSimGrid3D:RefreshLandform()
	if not self.IsLoaded then
		return
	end

	if self.Grid.LandformId == 0 then
		self.LandformLink.gameObject:SetActiveEx(false)
		return
	end

	local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
	if landformCfg.Model == nil then
		self.LandformLink.gameObject:SetActiveEx(false)
		return
	end

	self.LandformLink.gameObject:SetActiveEx(true)
	local go = self.LandformLink:LoadPrefab(landformCfg.Model)
	self.LandformMeshRenderer = go:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))

	-- TODO 正式模型设置好对应layer
	local allTrans = go.transform:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true)
	for i = 0, allTrans.Length - 1 do
	    allTrans[i].gameObject.layer = layerUiNear
	end

	local childs = self.Scene:GetChilds(self.Grid.Id)
	if childs then
		local gridCnt = #childs + 1 -- 该地貌的总占格
		local wolrdPos = self.Scene:GetWorldPosByGridId(self.Grid.Id)
		for _, childId in ipairs(childs) do
			local childWolrdPos = self.Scene:GetWorldPosByGridId(childId)
			wolrdPos = wolrdPos + childWolrdPos
		end
		local landPosY = self.LandformLink.transform.position.y
		self.LandformLink.transform.position = CS.UnityEngine.Vector3(wolrdPos.x / gridCnt, landPosY, wolrdPos.z / gridCnt)
		local linkPosY = self.UiGridCanvasLink.transform.position.y
		self.UiGridCanvasLink.transform.position = CS.UnityEngine.Vector3(wolrdPos.x / gridCnt, linkPosY, wolrdPos.z / gridCnt)
	end

	self:RefreshLandformShow()
end

-- 刷新地貌的显示
function XRogueSimGrid3D:RefreshLandformShow()
	if self.LandformMeshRenderer then
		local isBlock = self.Grid:GetIsBlock()
		self.LandformMeshRenderer.gameObject:SetActiveEx(not isBlock)
	end
end

-- 加载云雾
function XRogueSimGrid3D:LoadCloud()
	if not self.IsLoaded or self.CloudMeshRenderer then
		return
	end

	local cloudGo = CSInstantiate(self.Scene.Cloud1, self.CloudLink)
	cloudGo.gameObject:SetActiveEx(true)
	self.CloudMeshRenderer = cloudGo:GetComponent(typeof(CS.UnityEngine.MeshRenderer))

	-- 区域未解锁时，设置对应未解锁材质
	if not self.Grid.IsAreaUnlock then
		local material = self.Scene:GetCloudUnlockMaterial(self.Grid.AreaId)
		self.Scene.RogueSimHelper:AlterCloudMaterial(self.CloudMeshRenderer, material)
	end
end

-- 云雾解锁
function XRogueSimGrid3D:UnlockCloud()
	if not self.IsLoaded or not self.CloudMeshRenderer then
		return
	end

	-- 设置为区域解锁云朵材质
	if not self.IsDissolve then
		self.Scene.RogueSimHelper:RevertAlteredCloud(self.CloudMeshRenderer, XEnumConst.RogueSim.MapCloudAnimTime)
	end
end

-- 获取云雾解锁的Render
function XRogueSimGrid3D:GetUnlockCloudRender()
	if not self.IsDissolve and self.CloudMeshRenderer then
		return self.CloudMeshRenderer
	end
	return
end

-- 移除云雾
function XRogueSimGrid3D:RemoveCloud()
	if not self.IsLoaded or not self.CloudMeshRenderer then
		return
	end

	if not self.IsDissolve then
		self.Scene.RogueSimHelper:DissolveCloudRenderer(self.CloudMeshRenderer, XEnumConst.RogueSim.MapCloudAnimTime, false)
		self.IsDissolve = true
	end
	self:RefreshLandformShow()
end

-- 获取云雾移除的Render
function XRogueSimGrid3D:GetRemoveCloudRender()
	if not self.IsDissolve and self.CloudMeshRenderer then
		self.IsDissolve = true
		return self.CloudMeshRenderer
	end
	return
end

-- 设置压黑
function XRogueSimGrid3D:Darken()
	if not self.IsLoaded then
		return
	end

	if not self.IsDark then
		if self.TerrainMeshRenderer then
			self.Scene.RogueSimHelper:DarkenRenderer(self.TerrainMeshRenderer, true)
		end
		if self.LandformMeshRenderer then
			self.Scene.RogueSimHelper:DarkenRenderer(self.LandformMeshRenderer, true)
		end
		self.IsDark = true
	end
end

-- 移除压黑
function XRogueSimGrid3D:RemoveDarken()
	if not self.IsLoaded then
		return
	end

	if self.IsDark then
		if self.TerrainMeshRenderer then
			self.Scene.RogueSimHelper:TurnDarkenRendererIntoLight(self.TerrainMeshRenderer, true, XEnumConst.RogueSim.MapDarkToLightTime)
		end
		if self.LandformMeshRenderer then
			self.Scene.RogueSimHelper:TurnDarkenRendererIntoLight(self.LandformMeshRenderer, true, XEnumConst.RogueSim.MapDarkToLightTime)
		end
		self.IsDark = false
	end
end

-- 加载已探索特效
function XRogueSimGrid3D:LoadExploredEffect()
	if not self.IsLoaded then
		return
	end

	local landType = self.Grid:GetLandType()
	local effectPath
	if landType == XEnumConst.RogueSim.LandformType.City then
		effectPath = self._Control:GetClientConfig("CityExploredEffect")
	end

	if effectPath then
		self.ExploredEffectLink:LoadPrefab(effectPath, false)
	end
end

return XRogueSimGrid3D