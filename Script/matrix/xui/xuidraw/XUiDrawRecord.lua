--- 抽卡历史记录查看界面
---@class XUiDrawRecord: XLuaUi
---@field DrdSort UnityEngine.UI.Dropdown
local XUiDrawRecord = XLuaUiManager.Register(XLuaUi, 'UiDrawRecord')
local TypeText = {}
local CSArrayIndexToLuaTableIndex = function(index) return index + 1 end
local XUiGridDrawRecordLog = require('XUi/XUiDraw/XUiGridDrawRecordLog')
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString


local LogMaxInPage = 10 -- 每页最多展示多少个记录

function XUiDrawRecord:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnLast, self.OnBtnLastPageClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextPageClick)
    
    self:InitDropdownItemColorConfig()
end

function XUiDrawRecord:OnStart(defaultDrawId, historyGroupInfos)
    self.SelectDrawGroupId = defaultDrawId
    self.HistoryGroupInfos = historyGroupInfos
    self.CurrentPage = 0
    self.PageMax = 0
    self:InitTypeText()
    self:InitLogPool()
    self:InitDrawDropdown()
end

function XUiDrawRecord:OnDestroy()
    if self._DrdOpenTimeId then
        XScheduleManager.UnSchedule(self._DrdOpenTimeId)
        self._DrdOpenTimeId = nil
    end
end

--region 初始化

function XUiDrawRecord:InitDropdownItemColorConfig()
    local selectColorCfg = CS.XGame.ClientConfig:GetString('DrawRecordDropdownItemSelectColor')
    local normalColorCfg = CS.XGame.ClientConfig:GetString('DrawRecordDropdownItemNormalColor')

    if not string.IsNilOrEmpty(selectColorCfg) then
        self.DropdownItemSelectColor = XUiHelper.Hexcolor2Color(string.gsub(selectColorCfg, '#', ''))
    end

    if not string.IsNilOrEmpty(normalColorCfg) then
        self.DropdownItemNormalColor = XUiHelper.Hexcolor2Color(string.gsub(normalColorCfg, '#', ''))
    end
end

--- 初始化卡池选择下拉列表
function XUiDrawRecord:InitDrawDropdown()
    -- 给下拉框模板增加mono监听，以支持动态设置选项内容的需求
    self.DrdSort.template.gameObject:SetActiveEx(false)
    ---@type XLuaBehaviour
    self.DrdTemplateBehaviour = self.DrdSort.template.gameObject:AddComponent(typeof(CS.XLuaBehaviour))
    
    -- 打开下拉框时，为了克隆，Unity会先激活Template，触发enable。之后再执行克隆并改名的操作。
    -- 而节点的数据同步在下一帧执行，因此需要隔一帧
    self.DrdTemplateBehaviour.LuaOnEnable = function()

        if self._DrdOpenTimeId then
            XScheduleManager.UnSchedule(self._DrdOpenTimeId)
            self._DrdOpenTimeId = nil
        end
        
        self._DrdOpenTimeId = XScheduleManager.ScheduleNextFrame(handler(self, self.OnDrawListOpen))
    end
    
    -- 排序
    table.sort(self.HistoryGroupInfos, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        
        return a.DrawGroupId > b.DrawGroupId
    end)
    
    self.Index2GroupIdMap = {}
    self.DrawGroupId2IndexMap = {}

    self.DrdSort:ClearOptions()
    self._DropItemImages = {}
    
    local CsDropdown = CS.UnityEngine.UI.Dropdown
    local index = 1
    for _, drawGroupInfo in ipairs(self.HistoryGroupInfos) do
        ---@type XTableDrawGroupRule
        local cfg = XDrawConfigs.GetDrawGroupRuleById(drawGroupInfo.DrawGroupId)
        if cfg then
            local op = CsDropdown.OptionData()
            op.text = cfg.TitleCN
            self.DrdSort.options:Add(op)

            self.DrawGroupId2IndexMap[drawGroupInfo.DrawGroupId] = index
            self.Index2GroupIdMap[index] = drawGroupInfo
            index = index + 1
        end
    end
    self.DrdSort.value = self.DrawGroupId2IndexMap[self.SelectDrawGroupId] - 1

    self.DrdSort.onValueChanged:AddListener(function()
        self:OnDrawDropdownValueChaned(CSArrayIndexToLuaTableIndex(self.DrdSort.value))
    end)

    self:OnDrawDropdownValueChaned(CSArrayIndexToLuaTableIndex(self.DrdSort.value))
end

function XUiDrawRecord:InitTypeText()
    TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XMVCA.XCharacter:GetCharacterType(templateId)
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            return CS.XTextManager.GetText("TypeCharacter")
        elseif characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            return CS.XTextManager.GetText("TypeIsomer")
        end
    end
    TypeText[XArrangeConfigs.Types.Weapon] = CS.XTextManager.GetText("TypeWeapon")
    TypeText[XArrangeConfigs.Types.Wafer] = CS.XTextManager.GetText("TypeWafer")
    TypeText[XArrangeConfigs.Types.Fashion] = CS.XTextManager.GetText("TypeFashion")
    TypeText[XArrangeConfigs.Types.Furniture] = CS.XTextManager.GetText("TypeFurniture")
    TypeText[XArrangeConfigs.Types.HeadPortrait] = CS.XTextManager.GetText("TypeHeadPortrait")
    TypeText[XArrangeConfigs.Types.ChatEmoji] = CS.XTextManager.GetText("TypeChatEmoji")
    TypeText[XArrangeConfigs.Types.Partner] = CS.XTextManager.GetText("TypePartner")
end

function XUiDrawRecord:InitLogPool()
    ---@type XPool
    self.LowGridPool = XPool.New(function() 
        local go = CS.UnityEngine.Object.Instantiate(self.GridLogLow, self.GridLogLow.transform.parent)
        return XUiGridDrawRecordLog.New(go, self)
    end, function(grid) 
        grid:Close()
    end, false)
    
    ---@type XPool
    self.MidGridPool = XPool.New(function()
        local go = CS.UnityEngine.Object.Instantiate(self.GridLogMid, self.GridLogMid.transform.parent)
        return XUiGridDrawRecordLog.New(go, self)
    end, function(grid)
        grid:Close()
    end, false)
    
    ---@type XPool
    self.HighGridPool = XPool.New(function()
        local go = CS.UnityEngine.Object.Instantiate(self.GridLogHigh, self.GridLogHigh.transform.parent)
        return XUiGridDrawRecordLog.New(go, self)
    end, function(grid)
        grid:Close()
    end, false)

    self.GridLogLow.gameObject:SetActiveEx(false)
    self.GridLogMid.gameObject:SetActiveEx(false)
    self.GridLogHigh.gameObject:SetActiveEx(false)

    self.LowGridList = {}
    self.MidGridList = {}
    self.HighGridList = {}
end

--endregion

--region 界面刷新

function XUiDrawRecord:RefreshAll()
    self:RefreshPageProcessShow()
    self:RefreshRecordShow()
    self:RefreshPageChangeState()
    self:RefreshBottomTimesShow()
end

function XUiDrawRecord:RefreshPageProcessShow()
    self.PageTxt.text = self.CurrentPage..'/'..self.PageMax
end

function XUiDrawRecord:RefreshPageChangeState()
    if self.RecordSwichBtn then
        self.RecordSwichBtn.gameObject:SetActiveEx(self.PageMax > 1 )
    end
end

function XUiDrawRecord:RefreshBottomTimesShow()
    local Rules = XDataCenter.DrawManager.GetDrawGroupRule(self.SelectDrawGroupId)
    
    local drawTimes = self.MaxBottomTimes - self.BottomTimes
    
    if Rules.SpecialBottomMin > 0 and Rules.SpecialBottomMax > 0 then
        self.TxtEnsureCount.text = Rules.BottomText .. " " .. drawTimes .. "/(" .. Rules.SpecialBottomMin .. "~" .. Rules.SpecialBottomMax .. ")"
    else
        self.TxtEnsureCount.text = Rules.BottomText .. " " .. drawTimes .. "/" .. self.MaxBottomTimes
    end
end

function XUiDrawRecord:RefreshRecordShow()
    --- 回收
    if not XTool.IsTableEmpty(self.LowGridList) then
        for i = #self.LowGridList, 1, -1 do
            self.LowGridPool:ReturnItemToPool(self.LowGridList[i])
            table.remove(self.LowGridList, i)
        end
    end

    if not XTool.IsTableEmpty(self.MidGridList) then
        for i = #self.MidGridList, 1, -1 do
            self.MidGridPool:ReturnItemToPool(self.MidGridList[i])
            table.remove(self.MidGridList, i)
        end
    end

    if not XTool.IsTableEmpty(self.HighGridList) then
        for i = #self.HighGridList, 1, -1 do
            self.HighGridPool:ReturnItemToPool(self.HighGridList[i])
            table.remove(self.HighGridList, i)
        end
    end
    
    local hasHistoryShow = self.HistoryRewardCount > 0 and (self.CurrentPage - 1) * LogMaxInPage < self.HistoryRewardCount

    if self.EmptyRoot then
        self.EmptyRoot.gameObject:SetActiveEx(not hasHistoryShow)
    end
    
    -- 根据记录和当前页数进行显示
    if hasHistoryShow then
        --- 每页展示n个（举例10个），因为逆序展示，需要计算非整页的余量
        local mod = math.fmod(self.HistoryRewardCount, LogMaxInPage)
        --- 逆序需要从最末尾开始向前读，由于末尾基准值是当前区间的上限（例如1-10范围，基准就是10）
        --- 因此需要反向计算出减量（例如实际只有4条，那么基准值需要从10向前调整（10-4）6个单位
        local modDiff = mod > 0 and LogMaxInPage - mod or 0
        --- 根据当前页数算出展示的起始基准索引，页数范围是[1, n]
        --- 总页数-当前页数是上一页的起始值，所以需要+1
        local beginIndex = math.min((self.PageMax - self.CurrentPage + 1) * LogMaxInPage - modDiff, self.HistoryRewardCount)
        --- 末尾值是在当前起始值的基础上，向前调整9（10-1）个单位
        local endIndex = math.max(1, beginIndex - (LogMaxInPage - 1))
        
        -- 检查每一页索引区域是否正常的log
        --if XMain.IsDebug then
        --    XLog.Error('['..tostring(beginIndex)..', '..tostring(endIndex)..']')
        --end
        
        for i = beginIndex, endIndex, -1 do
            local reward = self.HistoryRewardList[i]
            local name
            local quality
            local fromName
            local time
            
            if reward.RewardGoods.ConvertFrom ~= 0 then
                local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.RewardGoods.ConvertFrom)
                local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.RewardGoods.TemplateId)
                quality = fromGoods.Quality
                quality = quality or 1
                fromName = fromGoods.Name
                if fromGoods.TradeName then
                    fromName = fromName .. "." .. fromGoods.TradeName
                end
                name = Goods.Name
                time = TimestampToGameDateTimeString(reward.DrawTime)
                self:_SetLogData(fromName, reward.RewardGoods.ConvertFrom, name, time, quality)
            else
                local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.RewardGoods.TemplateId)
                quality = Goods.Quality
                quality = quality or 1
                name = Goods.Name
                if Goods.TradeName then
                    name = name .. "." .. Goods.TradeName
                end
                time = TimestampToGameDateTimeString(reward.DrawTime)
                self:_SetLogData(name, reward.RewardGoods.TemplateId, nil, time, quality)
            end
        end
    end
end

function XUiDrawRecord:_SetLogData(name, templateId, from, time, quality)
    local itemType = XArrangeConfigs.GetType(templateId)
    local grid
    if itemType == XArrangeConfigs.Types.Character or itemType == XArrangeConfigs.Types.Partner then
        if quality >= XItemConfigs.Quality.Three then
            grid = self.HighGridPool:GetItemFromPool()
            table.insert(self.HighGridList, grid)
        else
            grid = self.MidGridPool:GetItemFromPool()
            table.insert(self.MidGridList, grid)
        end
    else
        if quality == XItemConfigs.Quality.Six then
            grid = self.HighGridPool:GetItemFromPool()
            table.insert(self.HighGridList, grid)
        elseif quality == XItemConfigs.Quality.Five then
            grid = self.MidGridPool:GetItemFromPool()
            table.insert(self.MidGridList, grid)
        else
            grid = self.LowGridPool:GetItemFromPool()
            table.insert(self.LowGridList, grid)
        end
    end

    grid.TxtName.text = name

    if type(TypeText[itemType]) == "function" then
        grid.TxtType.text = TypeText[itemType](templateId)
    else
        grid.TxtType.text = TypeText[itemType]
    end

    if not from then
        grid.TxtTo.gameObject:SetActiveEx(false)
    else
        grid.TxtTo.gameObject:SetActiveEx(true)
        grid.TxtTo.text = CS.XTextManager.GetText("ToOtherThing", from)
    end
    grid.TxtTime.text = time
    grid.Transform:SetAsLastSibling()
    grid:Open()
end

--endregion

--region 事件回调
function XUiDrawRecord:OnDrawDropdownValueChaned(index)
    self._Index = index
    local newGroupId = self.Index2GroupIdMap[index] and self.Index2GroupIdMap[index].DrawGroupId or 0

    if XTool.IsNumberValid(newGroupId) then
        XDataCenter.DrawManager.RequestDrawGroupGetHistory(newGroupId, function(res)
            self.SelectDrawGroupId = newGroupId
            self.HistoryRewardList = res.HistoryRewardList
            self.HistoryRewardCount = XTool.GetTableCount(res.HistoryRewardList)
            self.CurrentPage = 1
            self.BottomTimes = res.BottomTimes or 0
            self.MaxBottomTimes = res.MaxBottomTimes or 0
            self.PageMax = math.ceil(self.HistoryRewardCount / LogMaxInPage)
            self:RefreshAll()
        end, function()
            self:RefreshAll()
        end)
    end
end

function XUiDrawRecord:OnDrawListOpen()
    -- 没有颜色配置就不执行这里的逻辑
    if self.DropdownItemNormalColor == nil or self.DropdownItemSelectColor == nil then
        return
    end
    
    -- 查找dropdownlist节点
    ---@type UnityEngine.Transform
    local dropdownList = self.DrdSort.transform:Find('Dropdown List/Viewport/Content')
    local curIndexToCSharpIndex = self._Index - 1
    if dropdownList then
        -- 遍历子节点，设置底色
        local itemArray = dropdownList:GetComponentsInChildren(typeof(CS.UnityEngine.UI.Toggle), false)

        for i = 0, itemArray.Length - 1 do
            local bgImgGo = itemArray[i].transform:Find('ItemBackground')

            local bgImg = nil
            
            if bgImgGo then
                bgImg = bgImgGo:GetComponent(typeof(CS.UnityEngine.UI.Image))    
            end
            
            if bgImg then
                if i == curIndexToCSharpIndex then
                    bgImg.color = self.DropdownItemSelectColor
                else
                    bgImg.color = self.DropdownItemNormalColor
                end
            end
        end
    end
end


function XUiDrawRecord:OnBtnLastPageClick()
    if self.CurrentPage > 1 then
        self.CurrentPage = self.CurrentPage - 1
        self:RefreshRecordShow()
        self:RefreshPageProcessShow()
    end
end

function XUiDrawRecord:OnBtnNextPageClick()
    if self.CurrentPage < self.PageMax then
        self.CurrentPage = self.CurrentPage + 1
        self:RefreshRecordShow()
        self:RefreshPageProcessShow()
    end
end

--endregion

return XUiDrawRecord