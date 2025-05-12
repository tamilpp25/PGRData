---@class XUiGuildDormFurnitureMovieRandomBox : XUiGuildDormFurnitureMovieBase
local XUiGuildDormFurnitureMovieRandomBox = XLuaUiManager.Register(require('XUi/XUiGuildDorm/UiFurnitureMovie/XUiGuildDormFurnitureMovieBase'), 'UiGuildDormFurnitureMovieRandomBox')

local TabMap = {
    AgreeTab = 1,
    RefreshTab = 2,
    ClsoeTab = 3,
    StopTab = 1,
}

function XUiGuildDormFurnitureMovieRandomBox:OnAwake()
    self.Super.OnAwake(self)
    self:SetOptionCallBackProxyFunc(handler(self, self.OnBtnOptionClickProxyDefault))
end

function XUiGuildDormFurnitureMovieRandomBox:OnStart(furnitureId, randomBoxData)
    self._FurnitureId = furnitureId

    if randomBoxData._NoRandomTimes then
        self:DisplayRefuse()
    else
        self:RefreshContent(randomBoxData)
    end
end

function XUiGuildDormFurnitureMovieRandomBox:OnBtnOptionClickProxyDefault(index)
    if self._IsStop and index == TabMap.StopTab then
        self:Close()
        return
    end
    
    if index == TabMap.AgreeTab then
        self:Close()
    elseif index == TabMap.RefreshTab then
        local randomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(self._RandomBoxData.FurnitureId)
        if randomBoxCfg.RandomTimes <= self._RandomBoxData.RandomTimes then
            self:DisplayRefuse()
        else
            XDataCenter.GuildDormManager.RequestGuildDormCallRandomBox(self._FurnitureId, function(data)
                self:RefreshContent(data)
            end)
        end
    elseif index == TabMap.ClsoeTab then
        self:Close()
    end
end

function XUiGuildDormFurnitureMovieRandomBox:RefreshContent(randomBoxData)
    ---@type XTableGuildDormFurniture
    local furnitureCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, randomBoxData.FurnitureId)
    local randomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(randomBoxData.FurnitureId)

    self._RandomBoxData = randomBoxData
    
    local contentformatIndex = math.floor(CS.UnityEngine.Random.Range(1, #randomBoxCfg.InteractionTexts + 1))
    local contentFormat = randomBoxCfg.InteractionTexts[contentformatIndex]

    if contentFormat then
        local cfg = XGuildDormConfig.GetFurnitureRandomBoxItem(randomBoxData.RandomItemId)
        if cfg then
            local content = XUiHelper.FormatText(contentFormat, cfg.Name)
            self:SetDialog(furnitureCfg.Name, content)
        end
    else
        XLog.Error('家具对话句式不存在，请检查配置:','Id:'..tostring(contentformatIndex))
    end
    
    local optionList = {
        randomBoxCfg.AgreeReply,
        XUiHelper.FormatText(XGuildDormConfig.GetRandomBoxRandomLeftTimesFormat(), randomBoxCfg.RefreshReply, randomBoxCfg.RandomTimes - randomBoxData.RandomTimes),
        randomBoxCfg.CloseReply,
    }
    
    self:SetOptions(optionList)
end

function XUiGuildDormFurnitureMovieRandomBox:DisplayRefuse()
    self._IsStop = true

    local furnitureCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, self._FurnitureId)
    local randomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(self._FurnitureId)

    self:SetDialog(furnitureCfg.Name, randomBoxCfg.StopRefreshText)
    self:SetOptions({ randomBoxCfg.StopRefreshReply })
end

return XUiGuildDormFurnitureMovieRandomBox