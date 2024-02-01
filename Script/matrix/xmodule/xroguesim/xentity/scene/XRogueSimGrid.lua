-- 肉鸽模拟经营场景地图节点
---@class XRogueSimGrid
local XRogueSimGrid = XClass(nil, "XRogueSimGrid")
local layerUiNear = 24

function XRogueSimGrid:Ctor(scene, gridCfg, isAreaUnlock)
	self.Scene = scene
	self._Control = scene._MainControl
	self.Id = gridCfg.Id
	self.AreaId = gridCfg.AreaId
	self.PosX = gridCfg.PosX
	self.PosY = gridCfg.PosY
	self.TerrainId = gridCfg.TerrainId
	self.LandformId = gridCfg.LandformId
	self.ParentId = gridCfg.ParentId
	self:InitLandformId()

    self.IsAreaUnlock = isAreaUnlock	-- 区域是否解锁，由主城升级解锁
	self.IsExplored = false 			-- 是否已探索
	self.CanExplore = false 			-- 是否可探索
	self.CanBeSeen = false 				-- 是否可见，由已探索格子通过视距计算
	self.IsPreview = false 				-- 是否可预览，服务器下发的visibleId + 地貌表配置IsPreview为1

	local XRogueSimGrid3D = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid3D")
	self.Grid3D = XRogueSimGrid3D.New(self.Scene, self)
	local XRogueSimGrid2D = require("XModule/XRogueSim/XEntity/Scene/XRogueSimGrid2D")
	self.Grid2D = XRogueSimGrid2D.New(self.Scene, self)
end

-- 加载
function XRogueSimGrid:Load()
	self.Grid3D:Load()
	if self.Grid2D:IsNeedShow() then
		self.Grid2D:Load()
	end
end

-- 释放
function XRogueSimGrid:Release()
	self.Grid3D:Release()
	self.Grid3D = nil
	self.Grid2D:Release()
	self.Grid2D = nil
	self.Scene = nil
	self._Control = nil
end

function XRogueSimGrid:Refresh()
	self.Grid3D:Refresh()
	self.Grid2D:Refresh()
end

-- 设置区域已解锁
function XRogueSimGrid:SetAreaUnlock()
	self.IsAreaUnlock = true
	local unlockRender = self.Grid3D:GetUnlockCloudRender()
	local removeRender
	if not self:GetIsBlock() then
		removeRender = self.Grid3D:GetRemoveCloudRender()
	end
	return unlockRender, removeRender
end

-- 设置已探索
function XRogueSimGrid:SetExplored()
	if not self.IsExplored then
		self.IsExplored = true
		self:CheckChangeLandform()
		self.Grid3D:RefreshLandform()
		self.Grid3D:LoadExploredEffect()
		self.Grid2D:Refresh()
	end
end

-- 设置可探索
function XRogueSimGrid:SetCanExplore()
	self.CanExplore = true
	self.Grid3D:RemoveDarken()
end

-- 获取是否可探索
function XRogueSimGrid:GetCanExplore()
	return self.CanExplore
end

-- 设置可见
function XRogueSimGrid:SetCanBeSeen()
	self.CanBeSeen = true

	if not self:GetIsBlock() then
		self.Grid3D:RemoveCloud()
		self.Grid2D:Refresh()
	end
end

-- 获取是否可见
function XRogueSimGrid:GetCanBeSeen()
	return self.CanBeSeen
end

-- 设置可预览
function XRogueSimGrid:SetIsPreview()
	self.IsPreview = true

	if not self:GetIsBlock() then
		self.Grid3D:RemoveCloud()
		self.Grid2D:Refresh()
	end
end

-- 设置显示/隐藏
function XRogueSimGrid:SetShow(isShow)
	self.Grid3D:Show(isShow)
	self.Grid2D:Show(isShow)
end


-- 刷新主城可升级按钮
function XRogueSimGrid:RefreshMainLevelUp()
	self.Grid2D:Refresh()
end

-- 刷新城邦任务
function XRogueSimGrid:RefreshTask()
	self.Grid2D:Refresh()
end

-- 主城升级
function XRogueSimGrid:OnMainLevelUp()
	self:CheckChangeLandform()
	self.Grid3D:RefreshLandform()
	self.Grid2D:Refresh()
end

-- 添加建筑购买
function XRogueSimGrid:OnBuildingAdd()
	self.Grid2D:Refresh()
end

-- 建筑购买
function XRogueSimGrid:OnBuildingBuy()
	self:CheckChangeLandform()
	self.Grid3D:RefreshLandform()
	self.Grid2D:Refresh()
end

-- 增加事件
function XRogueSimGrid:OnEventAdd()
	self.Grid2D:Refresh()
end

-- 移除事件
function XRogueSimGrid:OnEventRemove()
	self:CheckChangeLandform()
	self.Grid3D:RefreshLandform()
	self.Grid2D:Refresh()
end

-- 增加点位奖励选择
function XRogueSimGrid:OnRewardAdd()
	self.Grid2D:Refresh()
end

-- 移除点位奖励选择
function XRogueSimGrid:OnRewardRemove()
	self:CheckChangeLandform()
	self.Grid3D:RefreshLandform()
	self.Grid2D:Refresh()
end

-- 初始化地貌Id
function XRogueSimGrid:InitLandformId()
 	-- 服务器随机格子数据
    local gridData = self._Control.MapSubControl:GetGridData(self.Id)
    if gridData then
    	self.LandformId = gridData.LandformId
		self.ParentId = gridData.ParentId
    end

    local landformType = self:GetLandType()
	if landformType == XEnumConst.RogueSim.LandformType.City then
		-- 地图只配置1级城邦点、2级城邦点、3级城邦点，需要根据随机到的城邦Id确定地貌
		local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Id)
		self.LandformId = self._Control.MapSubControl:GetCityLandformId(cityData.ConfigId)
	end
end

-- 检查改变地貌
function XRogueSimGrid:CheckChangeLandform()
	if self.LandformId == 0 then
		return
	end

	-- 根据地貌类型
	local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.LandformId)
	if landformCfg.LandType == XEnumConst.RogueSim.LandformType.Main then
		local curLevel = self._Control:GetCurMainLevel()
		self.LandformId = self._Control:GetMainLevelLandformId(curLevel)

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Building then
		local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Id)
	    if buildData and buildData:CheckIsBuy() then -- 建筑已建造
	    	self.LandformId = self._Control.MapSubControl:GetBuildingLandformId(buildData:GetConfigId())
	    end

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Event then
		local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Id)
		if landformCfg.FinishLandformId ~= 0 and not eventData then -- 事件已处理
			self.LandformId = landformCfg.FinishLandformId
		end

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Prop then
		local rewardData = self._Control:GetRewardDataByGridId(self.Id)
	    if landformCfg.FinishLandformId ~= 0 and (not rewardData or rewardData:GetPick()) then -- 道具已选择
	    	self.LandformId = landformCfg.FinishLandformId
	    end

	else
		if landformCfg.FinishLandformId ~= 0 then
			self.LandformId = landformCfg.FinishLandformId
		end
	end
end


function XRogueSimGrid:GetId()
	return self.Id
end

-- 获取父格子id
function XRogueSimGrid:GetParentId()
	return self.ParentId ~= 0 and self.ParentId or self.Id
end

-- 获取地貌
function XRogueSimGrid:GetLandformId()
	return self.LandformId
end

-- 获取名称
function XRogueSimGrid:GetName()
	if self.LandformId ~= 0 then
		return self._Control.MapSubControl:GetLandformName(self.LandformId)
	end

	return ""
end

-- 获取地貌类型
function XRogueSimGrid:GetLandType()
	if self.LandformId ~= 0 then
		return self._Control.MapSubControl:GetLandformLandType(self.LandformId)
	end

	return 0
end

-- 是否显示阻挡
function XRogueSimGrid:GetIsBlock()
	-- 区域未解锁
	if not self.IsAreaUnlock then
		return true
	end

	-- 可预览/可见
	if self.IsPreview or self.CanBeSeen then
		return false
	end
	return true
end

-- 是否不可点击
function XRogueSimGrid:GetIsUnClick()
	if self:GetIsBlock() then
		return true
	end

	-- 无地貌
	if self.LandformId == 0 then
		return true
	end

	-- 装饰用，无效果
	local mapSubControl = self._Control.MapSubControl
	local landformCfg = mapSubControl:GetRogueSimLandformConfig(self.LandformId)
	if landformCfg.LandType == XEnumConst.RogueSim.LandformType.Decoration then
		return true
	end

	return false
end

-- 获取不可点击提示
function XRogueSimGrid:GetUnClickTips()
	-- 区域未解锁
	if not self.IsAreaUnlock then
		local areaIds = self._Control.MapSubControl:GetAreaIds()
		local index = 0
		for i, areaId in ipairs(areaIds) do
			if self.AreaId == areaId then
				index = i
			end
		end

		local levelIds = self._Control:GetMainLevelList()
		for _, id in ipairs(levelIds) do
			local unlockIdx = self._Control:GetMainLevelUnlockAreaIdx(id)
			if unlockIdx == index then
				local lv = self._Control:GetMainLevelConfigLevel(id)
				return string.format(self._Control:GetClientConfig("AreaUnlockTips"), lv)
			end
		end
	end

	-- 不可预览 且 不可见
	if not self.IsPreview and not self.CanBeSeen then
		return self._Control:GetClientConfig("GridUnlockTips")
	end
end

-- 获取是否是区域已解锁
function XRogueSimGrid:GetIsAreaUnlock()
	return self.IsAreaUnlock
end

return XRogueSimGrid