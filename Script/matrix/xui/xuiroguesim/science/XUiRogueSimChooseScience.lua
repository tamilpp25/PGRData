-- 科技数详情
---@class XUiRogueSimChooseScience : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChooseScience = XLuaUiManager.Register(XLuaUi, "UiRogueSimChooseScience")

function XUiRogueSimChooseScience:OnAwake()
	self.BtnYes.gameObject:SetActiveEx(false)

	self.TechUiObjs = {self.GridScience}
    self:RegisterUiEvents()
end

function XUiRogueSimChooseScience:OnStart(techLv, isUnlock, onActiveCb)
	self.TechLv = techLv -- 科技树等级
	self.IsUnlock = isUnlock -- 是否已解锁
	self.OnActiveCb = onActiveCb -- 激活科技回调

	self.TechIds = {}
	self.SelectDic = {}
	self.CanSelectNum = self:GetCanSelectNum()
end

function XUiRogueSimChooseScience:OnEnable()
	self:RefreshTips()
    self:RefreshAsset()
	self:RefreshTechs()
	self:RefreshSelectNum()
end

function XUiRogueSimChooseScience:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnUnlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.Close)
end

function XUiRogueSimChooseScience:OnBtnScienceClick(index)
	local uiObj = self.TechUiObjs[index]
	local isSelect = self.SelectDic[index] == true
	if isSelect then
		self.SelectDic[index] = false
		uiObj:GetObject("PanelSelect").gameObject:SetActiveEx(false)
	else
		-- 只能选1个
		if self.CanSelectNum == 1 then
			for i, uiObj in ipairs(self.TechUiObjs) do
				local isSelect = i == index
				uiObj:GetObject("PanelSelect").gameObject:SetActiveEx(isSelect)
				self.SelectDic[i] = isSelect
			end
		else
			local curSelNum = self:GetCurSelectNum()
			if curSelNum < self.CanSelectNum then
				self.SelectDic[index] = true
				uiObj:GetObject("PanelSelect").gameObject:SetActiveEx(true)
			else
				local tips = self._Control:GetClientConfig("TechSelectFull")
		        XUiManager.TipError(tips)
			end
		end
	end
	self:RefreshSelectNum()

	local curSelNum = self:GetCurSelectNum()
	self.BtnYes.gameObject:SetActiveEx(curSelNum > 0)
end

function XUiRogueSimChooseScience:OnBtnUnlockClick()
	if not self.IsUnlock then
		local tips = self._Control:GetClientConfig("TechActivePreLevelTechTips")
		XUiManager.TipError(tips)
		return
	end

	-- 选择数量超过可解锁数量
	local curSelNum = self:GetCurSelectNum()
	if curSelNum > self.CanSelectNum then
		local tips = string.format(self._Control:GetClientConfig("TechNoSelectFullTips"), self.CanSelectNum)
		XUiManager.TipError(tips)
		return
	end

	-- 金币不够
	local techIds = {}
	local needCount = 0
	for i, isSelect in pairs(self.SelectDic) do
		local techId = self.TechIds[i]
		if isSelect then
			table.insert(techIds, techId)
			local techCfg = self._Control:GetRogueSimTechConfig(techId)
			needCount = needCount + self._Control:GetTechDiscountPrice(techCfg.Cost)
		end
	end

	local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    local isGoldEnough = own >= needCount
    if not isGoldEnough then
    	local tips = self._Control:GetClientConfig("TechGoldUnlockTips")
    	XUiManager.TipError(tips)
    	return
    end

    -- 请求解锁科技
	self._Control:RogueSimUnlockKeyTechRequest(techIds, function()
        if self.OnActiveCb then
        	self.OnActiveCb()
        end
        self:Close()
    end)
end

-- 再次解锁提示
function XUiRogueSimChooseScience:RefreshTips()
    local techLevelCfg = self._Control:GetRogueSimTechLevelConfig(self.TechLv)
	local showNextUnlock = techLevelCfg.NextUnlockLevel > 0
    self.TxtTips.gameObject:SetActiveEx(showNextUnlock)
    if showNextUnlock then
    	local techLvToMainLvDic = self:GetTechLvToMainLvDic()
    	local mainLv = techLvToMainLvDic[techLevelCfg.NextUnlockLevel]
    	self.TxtTips.text = string.format(self._Control:GetClientConfig("TechLevelNextUnlockTips"), mainLv)
    end
end

-- 获取 科技等级:主城等级 的哈希表
function XUiRogueSimChooseScience:GetTechLvToMainLvDic()
    local techLvToMainLvDic = {}
    local levelIds = self._Control:GetMainLevelList()
    for _, id in ipairs(levelIds) do
        local mainLv = self._Control:GetMainLevelConfigLevel(id)
        local techLv = self._Control:GetMainLevelUnlockTechLevel(id)
        techLvToMainLvDic[techLv] = mainLv
    end
    return techLvToMainLvDic
end

-- 刷新资源
function XUiRogueSimChooseScience:RefreshAsset()
	local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
	local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
	self.PanelAsset:GetObject("RImgGold"):SetRawImage(icon)
	self.PanelAsset:GetObject("TxtNum").text = tostring(own)
end

-- 刷新选中数量
function XUiRogueSimChooseScience:RefreshSelectNum()
    local curSelNum = self:GetCurSelectNum()
    local tips = self._Control:GetClientConfig("TechCanUnlockTips")
    self.TxtNum.text = string.format(tips, curSelNum, self.CanSelectNum)
end

-- 刷新科技列表
function XUiRogueSimChooseScience:RefreshTechs()
    for _, uiObj in ipairs(self.TechUiObjs) do
    	uiObj.gameObject:SetActiveEx(false)
    end
    self.TechIds = self:GetShowTechIds()
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
	local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
    for i, techId in ipairs(self.TechIds) do
    	local uiObj = self.TechUiObjs[i]
    	if not uiObj then
    		uiObj = CSInstantiate(self.GridScience, self.ListScience)
    		self.TechUiObjs[i] = uiObj
    	end
    	uiObj.gameObject:SetActiveEx(true)

    	local techCfg = self._Control:GetRogueSimTechConfig(techId)
    	self:SetUiSprite(uiObj:GetObject("ImgScience"), techCfg.Icon)
    	uiObj:GetObject("TxtName").text = techCfg.Name
    	uiObj:GetObject("TxtDetail").text = techCfg.Desc
    	uiObj:GetObject("PanelSelect").gameObject:SetActiveEx(false)
    	uiObj:GetObject("RImgCoin"):SetRawImage(icon)
    	local discountPrice = self._Control:GetTechDiscountPrice(techCfg.Cost)
    	uiObj:GetObject("TxtCoin").text = tostring(discountPrice)

    	local index = i
    	uiObj:GetObject("BtnScience").CallBack = function()
    		self:OnBtnScienceClick(index)
    	end
    end
end

-- 获取需要显示的科技id列表
function XUiRogueSimChooseScience:GetShowTechIds()
	-- 已激活的科技Id
    local techData = self._Control:GetTechData()
    local activeTechIdDic = {}
    for _, levelData in pairs(techData.LevelData) do
    	for _, techId in ipairs(levelData.KeyTechs) do
    		activeTechIdDic[techId] = true
    	end
    end

    -- 剔除已激活的科技
    local showTechIds = {}
    local techLevelCfg = self._Control:GetRogueSimTechLevelConfig(self.TechLv)
    for _, techId in ipairs(techLevelCfg.Techs) do
    	if not activeTechIdDic[techId] then
    		table.insert(showTechIds, techId)
    	end
    end

    return showTechIds
end

-- 获取当前选中科技的数量
function XUiRogueSimChooseScience:GetCurSelectNum()
	local num = 0
	for _, isSelect in pairs(self.SelectDic) do
		if isSelect then
			num = num + 1
		end
	end
	return num
end

-- 获取可选择科技的数量
function XUiRogueSimChooseScience:GetCanSelectNum()
	local techLevelCfg = self._Control:GetRogueSimTechLevelConfig(self.TechLv)
    local techData = self._Control:GetTechData()
    local levelData = techData.LevelData[self.TechLv]
    local unlockCnt = levelData and #levelData.KeyTechs or 0
    return techLevelCfg.Num - unlockCnt
end

return XUiRogueSimChooseScience
