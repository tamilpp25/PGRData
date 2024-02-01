-- 肉鸽模拟经营场景2D节点
local XRogueSimGrid2D = XClass(nil, "XRogueSimGrid2D")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XRogueSimGrid2D:Ctor(scene, grid)
	self.Scene = scene
	self.Grid = grid
	self._Control = self.Scene._MainControl
	self.IsLoaded = false -- 是否已加载
end

-- 加载
function XRogueSimGrid2D:Load()
    local gridGo = CSInstantiate(self.Scene.UiGridCanvas, self.Grid.Grid3D.UiGridCanvasLink)
    self.Transform = gridGo.transform
	self.GameObject = gridGo.gameObject
    self.GameObject:SetActiveEx(true)
	self.IsLoaded = true

	XTool.InitUiObject(self)
	self:OnLoaded()
end

function XRogueSimGrid2D:OnLoaded()
	self:RegisterUiEvents()
	self:Refresh()
end

function XRogueSimGrid2D:Release()
	XTool.ReleaseUiObjectIndex(self)
	self.Scene = nil
	self.Grid = nil
	self._Control = nil
	self.Transform = nil
	self.GameObject = nil
end

function XRogueSimGrid2D:RegisterUiEvents()
	self.BtnLevelUp.CallBack = function()
		self:OnBtnLevelUpClick()
	end
	self.BtnBuild.CallBack = function()
		self:OnBtnBuildClick()
	end
	self.BtnEvent.CallBack = function()
		self:OnBtnEventClick()
	end
	self.BtnItem.CallBack = function()
		self:OnBtnItemClick()
	end
	self.PanelTask:GetObject("BtnClick").CallBack = function()
		self:OnPanelTaskClick()
	end
end

-- 点击升级按钮
function XRogueSimGrid2D:OnBtnLevelUpClick()
	XLuaUiManager.Open("UiRogueSimLv")
end

-- 点击建造按钮
function XRogueSimGrid2D:OnBtnBuildClick()
	local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Grid:GetId())
    self._Control.MapSubControl:ExploreBuildingGrid(buildData:GetId())
end

-- 点击事件按钮
function XRogueSimGrid2D:OnBtnEventClick()
	local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
    self._Control.MapSubControl:ExploreEventGrid(eventData:GetId())
end

-- 点击选择道具按钮
function XRogueSimGrid2D:OnBtnItemClick()
	local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
    if rewardData and not rewardData:GetPick() then
        self._Control.MapSubControl:ExplorePropGrid(rewardData:GetId())
    end
end

-- 点击任务面板
function XRogueSimGrid2D:OnPanelTaskClick()

end

function XRogueSimGrid2D:Show(isShow)
	if not self.IsLoaded then
		return
	end

	self.GameObject:SetActiveEx(isShow)
end

-- 是否需要Ui显示，需要显示Ui内容才加载
function XRogueSimGrid2D:IsNeedShow()
	if self.Grid.LandformId == 0 or self.Grid:GetIsBlock() then
		return false
	end

	-- 配置Ui图标
	local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
	if landformCfg.ModelCenterIcon or landformCfg.ModelSideIcon then
		return true
	end

	-- 主城类型
	if landformCfg.LandType == XEnumConst.RogueSim.LandformType.Main then
		return true

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.City then
		return true

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Building then
		return true

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Event then
		local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
		if eventData then -- 有未处理事件
			return true
		end

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Prop then
		local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
	    if rewardData and not rewardData:GetPick() then -- 有未选择的道具
	    	return true
	    end

	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Resource then

	end

	return false
end

-- 刷新
function XRogueSimGrid2D:Refresh()
	-- 需要场景格子加载完成，挂于UiGridCanvasLink挂点
	if not self.Grid.Grid3D.IsLoaded then
		return
	end

	local needShow = self:IsNeedShow()
	if not needShow then
		if self.IsLoaded then
			self.GameObject.gameObject:SetActiveEx(false)
		end
		return
	end

	if not self.IsLoaded then
		self:Load()
	end
	self.GameObject.gameObject:SetActiveEx(true)

	-- Ui默认隐藏
	self.RImgCenter.gameObject:SetActiveEx(false)
	self.PanelMainName.gameObject:SetActiveEx(false)
	self.PanelCityName.gameObject:SetActiveEx(false)
	self.PanelBuidingName.gameObject:SetActiveEx(false)
	self.BtnLevelUp.gameObject:SetActiveEx(false)
	self.BtnBuild.gameObject:SetActiveEx(false)
	self.BtnEvent.gameObject:SetActiveEx(false)
	self.BtnItem.gameObject:SetActiveEx(false)
	self.PanelTask.gameObject:SetActiveEx(false)

	-- Ui图标
	self:RefreshIcon()

	-- 根据建筑类型刷新UI
	local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
	if landformCfg.LandType == XEnumConst.RogueSim.LandformType.Main then
		self:RefreshMain()
	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.City then
		self:RefreshCity()
	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Building then
		self:RefreshBuilding()
	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Event then
		self:RefreshEvent()
	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Prop then
		self:RefreshProp()
	elseif landformCfg.LandType == XEnumConst.RogueSim.LandformType.Resource then
		self:RefreshResource()
	end
end

-- 刷新图标
function XRogueSimGrid2D:RefreshIcon()
	local landformCfg = self._Control.MapSubControl:GetRogueSimLandformConfig(self.Grid.LandformId)
	if landformCfg.ModelCenterIcon ~= nil then
		self.RImgCenter.gameObject:SetActiveEx(true)
		self.RImgCenter:SetRawImage(landformCfg.ModelCenterIcon)
	end
end

-- 刷新主城类型
function XRogueSimGrid2D:RefreshMain()
	-- 名称
	self.PanelMainName.gameObject:SetActiveEx(true)
	self.TxtMainName.text = self.Grid:GetName()
	self.TxtMainLevel.text = self._Control:GetCurMainLevel()

	-- 可升级按钮
	local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
	if isCanLevelUp then
		self.BtnLevelUp.gameObject:SetActiveEx(true)
	end
end

-- 刷新城邦类型
function XRogueSimGrid2D:RefreshCity()
	-- 名称
	self.PanelCityName.gameObject:SetActiveEx(true)
	self.TxtCityName.text = self.Grid:GetName()

	-- 标志
	local tagIcon = self._Control.MapSubControl:GetLandformSideIcon(self.Grid.LandformId)
	self.RImgCityIcon:SetSprite(tagIcon)

	-- 城邦任务
	if self.Grid.IsExplored then
		local cityData = self._Control.MapSubControl:GetCityDataByGridId(self.Grid:GetId())
		if cityData then
			local taskId = self._Control.MapSubControl:GetCityTaskIdById(cityData:GetId())
			local configId = self._Control:GetTaskConfigIdById(taskId)
		    local isFinish = self._Control:CheckTaskIsFinished(taskId)
		    if not isFinish then
		    	self.PanelTask.gameObject:SetActiveEx(true)
		        local schedule, totalNum = self._Control:GetTaskScheduleAndTotalNum(taskId, configId)
		    	self.PanelTask:GetObject("TxtDetail").text = self._Control:GetTaskDesc(configId)
		        self.PanelTask:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(totalNum) and schedule / totalNum or 1
		    end
		end
	end
end

-- 刷新建筑类型
function XRogueSimGrid2D:RefreshBuilding()
	local buildData = self._Control.MapSubControl:GetBuildingDataByGridId(self.Grid:GetId())
    if buildData then
    	if buildData:CheckIsBuy() then
			-- 名称
			self.PanelBuidingName.gameObject:SetActiveEx(true)
			self.TxtBuidingName.text = self.Grid:GetName()
			-- 标志
			local tagIcon = self._Control.MapSubControl:GetLandformSideIcon(self.Grid.LandformId)
			self.RImgBuidingIcon:SetSprite(tagIcon)
       	else
			-- 未购买按钮
       		self.BtnBuild.gameObject:SetActiveEx(true)
       	end
    end
end

-- 刷新事件类型
function XRogueSimGrid2D:RefreshEvent()
	local eventData = self._Control.MapSubControl:GetEventDataByGridId(self.Grid:GetId())
	if eventData ~= nil then -- 有未处理事件
		self.BtnEvent.gameObject:SetActiveEx(true)
	end
end

-- 刷新道具类型
function XRogueSimGrid2D:RefreshProp()
	local rewardData = self._Control:GetRewardDataByGridId(self.Grid:GetId())
	if rewardData and not rewardData:GetPick() then -- 有未选择的道具
		self.BtnItem.gameObject:SetActiveEx(true)
	end
end

-- 刷新资源类型
function XRogueSimGrid2D:RefreshResource()

end

return XRogueSimGrid2D