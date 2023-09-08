local XUiPanelSetting = XLuaUiManager.Register(XLuaUi, "UiPanelSetting")

local XUiGridCollectionWall = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridCollectionWall")
local UiButtonState = CS.UiButtonState
local tableInsert = table.insert
local MAX_CHARACTER = 5
local ScoreTitleType = {
    Babel = 2
}
local ShowTypeIndex = {
    All = 1,
    Friend = 2,
    Self = 3
}

function XUiPanelSetting:OnStart(root)
    self.UiRoot = root
    self.UiRoot.UiPanelSetting = self

    self.SortedDormitoryList = {}        -- 拥有的宿舍数组，值为{ DormitoryId, DormitoryName }，索引从1开始，对应的下拉列表值为索引减1，按照宿舍号进行排序
    self.DormIdToDropValue = {}          -- 宿舍Id对应的下拉列表值，从0开始

    self.OldWallShowSetting = {}        -- 旧收藏品墙展示设置
    self.CurWallShowSetting = {}        -- 当前收藏品墙展示设置
    self.WallPool = {}                  -- XUiGridCollectionWall池子

    self.CharacterList = XPlayer.ShowCharacters
    self.RImgCharacter = {
        self.RImgCharacter1,
        self.RImgCharacter2,
        self.RImgCharacter3,
        self.RImgCharacter4,
        self.RImgCharacter5
    }
    self:AddListener()

    self:InitCollectionShowBtnGroup()
    self:InitMemberShowBtnGroup()
    self:InitFashionShowBtnGroup()
    self:InitWeaponShowBtnGroup()
    self:InitDormitoryShowBtnGroup()

    self:InitAppearanceSetting()
    self:UpdateCharacterHead()

    self:InitUnfold()
end

function XUiPanelSetting:Close()
    self.UiRoot:OnClickBtnBack()
end

---
--- 更新展示角色
function XUiPanelSetting:UpdateCharacterHead()
    for i = 1, #self.RImgCharacter do
        if not XTool.UObjIsNil(self.RImgCharacter[i]) then
            if self.CharacterList[i] then
                self.RImgCharacter[i].gameObject:SetActive(true)
                local charIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.CharacterList[i])
                self.RImgCharacter[i]:SetRawImage(charIcon)
            else
                self.RImgCharacter[i].gameObject:SetActive(false)
            end
        end
    end
end

---
--- 初始化展示设置
function XUiPanelSetting:InitAppearanceSetting()
    self.CurScoreTitleShowState = XDataCenter.MedalManager.GetScoreTitleShowState()
    self.OldScoreTitleShowState = XDataCenter.MedalManager.GetScoreTitleShowState()

    -- 是否全角色展示,0全部显示，1自己选择显示
    self.OldCharactersAppearanceType = XPlayer.GetAppearanceShowType()
    self.CurCharactersAppearanceType = XPlayer.GetAppearanceShowType()
    local isShowAllCharacter = self.CurCharactersAppearanceType and self.CurCharactersAppearanceType == XPlayerInfoConfigs.CharactersAppearanceType.All or false
    self.BtnAllCharacterShow:SetButtonState(isShowAllCharacter and UiButtonState.Select or UiButtonState.Normal)
    self.MemberContent.gameObject:SetActiveEx(not isShowAllCharacter)
    self.HadAllChar.gameObject:SetActiveEx(isShowAllCharacter)

    -- 展示设置，1全部可见，2朋友可见，3自己可见
    self.OldAppearanceSetting = XPlayer.GetAppearanceSettingInfo()
    self.CurAppearanceSetting = XPlayer.GetAppearanceSettingInfo()
    self.CollectionShowBtnGroup:SelectIndex(self.CurAppearanceSetting and self.CurAppearanceSetting.TitleType or ShowTypeIndex.All)
    self.MemberShowBtnGroup:SelectIndex(self.CurAppearanceSetting and self.CurAppearanceSetting.CharacterType or ShowTypeIndex.All)
    self.FashionShowBtnGroup:SelectIndex(self.CurAppearanceSetting and self.CurAppearanceSetting.FashionType or ShowTypeIndex.All)
    self.WeaponShowBtnGroup:SelectIndex(self.CurAppearanceSetting and self.CurAppearanceSetting.WeaponFashionType or ShowTypeIndex.All)
    self.DormitoryShowBtnGroup:SelectIndex(self.CurAppearanceSetting and self.CurAppearanceSetting.DormitoryType or ShowTypeIndex.All)

    --  判断宿舍系统是否开开启
    local isDormOpen =  XFunctionManager.JudgeCanOpen( XFunctionManager.FunctionName.Dorm)
    self.TxtDromNotOpen.gameObject:SetActiveEx(not isDormOpen)
    self.DormitoryShowBtnGroup.gameObject:SetActiveEx(isDormOpen)
    if isDormOpen then
        -- 设置宿舍下拉列表
        XPlayer.GetDormitoryList(function(dormitoryList)
            self:InitDormitoryDrop(dormitoryList)
        end)
    end

    -- 在聊天与个人信息展示本期巴别塔等级设置
    local IsBabelScoreTitleShow = XDataCenter.MedalManager.CheckScoreTitleIsShow(ScoreTitleType.Babel)
    self.BtnBabelScoreTitleShow:SetButtonState(IsBabelScoreTitleShow and UiButtonState.Select or UiButtonState.Normal)
    local IsHaveType = XDataCenter.MedalManager.CheckHaveScoreTitleType(ScoreTitleType.Babel)
    local IsInTime = XDataCenter.MedalManager.CheckScoreTitleInTimeByType(ScoreTitleType.Babel)
    self.BtnBabelScoreTitleShow.gameObject:SetActiveEx(IsHaveType and IsInTime)
end

---
--- 初始化折叠信息
function XUiPanelSetting:InitUnfold()
    local charUnfold = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "CharUnfold"))
    local displayUnfold = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "DisplayUnfold"))
    local collectionUnfold = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "CollectionUnfold"))

    if charUnfold == nil or charUnfold == false then
        self.BtnCharUnfold:SetButtonState(UiButtonState.Normal)
    else
        self.BtnCharUnfold:SetButtonState(UiButtonState.Select)
    end

    if displayUnfold == nil or displayUnfold == false then
        self.BtnDisplayUnfold:SetButtonState(UiButtonState.Normal)
    else
        self.BtnDisplayUnfold:SetButtonState(UiButtonState.Select)
    end

    if collectionUnfold == nil or collectionUnfold == 1 then
        self.BtnCollectionUnfold:SetButtonState(UiButtonState.Select)
    else
        self.BtnCollectionUnfold:SetButtonState(UiButtonState.Normal)
    end

    self:OnBtnCharUnfold()
    self:OnBtnDisplayUnfold()
    self:OnBtnCollectionUnfold()
end

---
--- 根据已解锁宿舍，初始化宿舍下拉列表
--- @param dormitoryList table 已解锁的宿舍数组，结构为{ DormitoryId, DormitoryName }
function XUiPanelSetting:InitDormitoryDrop(dormitoryList)
    if not dormitoryList or not next(dormitoryList) then
        XLog.Error("XUiPanelSetting:InitDormitoryDrop函数错误，dormitoryList为空")
        return
    end
    self.SortedDormitoryList = dormitoryList or {}

    -- 排序下拉列表的宿舍
    table.sort(self.SortedDormitoryList, function(a, b)
        local cfg1 = XDormConfig.GetDormitoryCfgById(a.DormitoryId)
        local cfg2 = XDormConfig.GetDormitoryCfgById(b.DormitoryId)
        return cfg1.InitNumber < cfg2.InitNumber
    end)

    -- 创建下拉列表选项
    local optionsDataList = CS.UnityEngine.UI.Dropdown.OptionDataList()
    for index, dorm in ipairs(self.SortedDormitoryList) do
        local optionContribute = CS.UnityEngine.UI.Dropdown.OptionData()
        optionContribute.text = dorm.DormitoryName
        optionsDataList.options:Add(optionContribute)
        self.DormIdToDropValue[dorm.DormitoryId] = index - 1
    end
    self.DormitoryDrop:ClearOptions()
    self.DormitoryDrop:AddOptions(optionsDataList.options)

    -- 未解锁宿舍系统时，登录推送的宿舍Id为0，解锁宿舍系统后需要初始化为默认的宿舍Id
    if self.CurAppearanceSetting.DormitoryId == 0 or self.OldAppearanceSetting.DormitoryId == 0 then
        if self.CurAppearanceSetting.DormitoryId ~= self.OldAppearanceSetting.DormitoryId then
            XLog.Error("XUiPanelSetting:InitDormitoryDrop函数错误，当前设置宿舍ID 与 旧设置宿舍ID 一个为0,另一个不为0")
        end

        if (self.SortedDormitoryList[1] or {}).DormitoryId then
            self.CurAppearanceSetting.DormitoryId = self.SortedDormitoryList[1].DormitoryId
            self.OldAppearanceSetting.DormitoryId = self.SortedDormitoryList[1].DormitoryId
        else
            XLog.Error("XUiPanelSetting:InitDormitoryDrop函数错误，展示设置宿舍Id为0，且SortedDormitoryList中没有宿舍数据")
        end
    end

    -- 选择对应的宿舍
    local dropValue = self.DormIdToDropValue[self.CurAppearanceSetting.DormitoryId]
    if dropValue then
        self.DormitoryDrop.value = dropValue
    else
        XLog.Error(string.format("XUiPanelSetting:CreateOptionsDataList函数错误，宿舍%s不在的解锁的宿舍数据中", tostring(self.CurAppearanceSetting.DormitoryId)))
        self.DormitoryDrop.value = 0
    end
end

---
--- 更改设置之后，检查与原来设置是否相同
--- 不相同则在退出时提示是否需要保存
function XUiPanelSetting:CheckSave()
    local needSave = false

    -- 选择展示的成员
    for i = 1, MAX_CHARACTER do
        if self.CharacterList[i] ~= XPlayer.ShowCharacters[i] then
            needSave = true
            break
        end
    end

    -- 在聊天与个人信息展示本期巴别塔等级设置
    for index, showState in pairs(self.OldScoreTitleShowState) do
        if self.CurScoreTitleShowState[index].Hide ~= showState.Hide then
            needSave = true
            break
        end
    end

    -- 展示设置
    for index, showState in pairs(self.OldAppearanceSetting) do
        if self.CurAppearanceSetting[index] ~= showState then
            needSave = true
            break
        end
    end

    -- 全角色展示
    if self.CurCharactersAppearanceType ~= self.OldCharactersAppearanceType then
        needSave = true
    end

    -- 收藏品墙展示
    for wallDataId, isShow in pairs(self.OldWallShowSetting) do
        if self.CurWallShowSetting[wallDataId] ~= isShow then
            needSave = true
            break
        end
    end

    self.UiRoot.NeedSave = needSave
end

function XUiPanelSetting:SaveScoreTitleShowData()
    local list = {}

    for index, showState in pairs(self.OldScoreTitleShowState) do
        if self.CurScoreTitleShowState[index].Hide ~= showState.Hide then
            tableInsert(list, self.CurScoreTitleShowState[index])
        end
    end
    if #list > 0 then
        XDataCenter.MedalManager.SetScoreTitleShow(list, function()
            self.CurScoreTitleShowState = XDataCenter.MedalManager.GetScoreTitleShowState()
            self.OldScoreTitleShowState = XDataCenter.MedalManager.GetScoreTitleShowState()
        end)
    end
end

---
--- 初始化收藏品墙展示设置
function XUiPanelSetting:InitCollectionWallShow()
    self.UseWallDic = {}            -- WallPool池子中正在使用的格子 { key:Id, value:XUiGridCollectionWall }
    self.OldWallShowSetting = {}
    self.CurWallShowSetting = {}
    self.GridCollectionWall.gameObject:SetActiveEx(false)

    for _, wall in pairs(self.WallPool) do
        wall.GameObject:SetActiveEx(false)
    end

    self.NormalCollectionWall = XDataCenter.CollectionWallManager.GetNormalWallEntityList()
    if #self.NormalCollectionWall <= 0 then
        self.CollectionWallNone.gameObject:SetActiveEx(true)
        self.BtnAllCollectionShow.gameObject:SetActiveEx(false)
        return
    end

    self.CollectionWallNone.gameObject:SetActiveEx(false)
    self.BtnAllCollectionShow.gameObject:SetActiveEx(true)

    local isShowAll = true
    for i, wallData in ipairs(self.NormalCollectionWall) do
        local isShow = wallData:GetIsShow()
        self.OldWallShowSetting[wallData:GetId()] = isShow
        self.CurWallShowSetting[wallData:GetId()] = isShow

        if isShow == false then
            -- 有一个收藏品墙不展示，所以不是全部展示
            isShowAll = false
        end

        if not self.WallPool[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCollectionWall)
            ui.transform:SetParent(self.CollectionWallContent, false)
            ui.gameObject:SetActive(true)

            local collectionWall = XUiGridCollectionWall.New(ui, self, XCollectionWallConfigs.EnumWallGridOpenType.Setting)
            self.WallPool[i] = collectionWall
        end
        self.WallPool[i]:UpdateGrid(wallData)
        self.WallPool[i].GameObject:SetActiveEx(true)

        self.UseWallDic[wallData:GetId()] = self.WallPool[i]
    end

    -- 设置全部展示的状态
    if isShowAll then
        self.BtnAllCollectionShow:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnAllCollectionShow:SetButtonState(CS.UiButtonState.Normal)
    end
end

---
--- 保存收藏品墙展示设置
--- 在发送协议后更新收藏品墙数据实体(XCollectionWall)IsShow属性
--- 然后在回调中更新设置缓存
function XUiPanelSetting:SaveCollectionWallShow()
    if #self.NormalCollectionWall <= 0 then
        -- 没有对外展示的墙
        return
    end

    -- 构造发送请求需要的数据
    local showInfoList = {}
    for id, isShow in pairs(self.CurWallShowSetting) do
        local showInfo = {}
        showInfo.Id = id
        showInfo.IsShow = isShow
        table.insert(showInfoList, showInfo)
    end

    XDataCenter.CollectionWallManager.RequestEditCollectionWallIsShow(showInfoList, function()
        -- 保存后更新新旧设置缓存
        for _, wallData in ipairs(self.NormalCollectionWall) do
            self.OldWallShowSetting[wallData:GetId()] = wallData:GetIsShow()
            self.CurWallShowSetting[wallData:GetId()] = wallData:GetIsShow()
        end
    end)
end


---------------------------------------------------添加按钮响应函数---------------------------------------------------------

function XUiPanelSetting:AddListener()
    self.BtnAllCharacterShow.CallBack = function()
        self:OnBtnAllCharacterShow()
    end
    self.BtnCharacter1.CallBack = function()
        self:OnBtnCharacter(1)
    end
    self.BtnCharacter2.CallBack = function()
        self:OnBtnCharacter(2)
    end
    self.BtnCharacter3.CallBack = function()
        self:OnBtnCharacter(3)
    end
    self.BtnCharacter4.CallBack = function()
        self:OnBtnCharacter(4)
    end
    self.BtnCharacter5.CallBack = function()
        self:OnBtnCharacter(5)
    end

    self.BtnBabelScoreTitleShow.CallBack = function()
        self:OnBtnBabelScoreTitleShow()
    end
    self.BtnSave.CallBack = function()
        self:OnBtnSave()
    end
    self.BtnView.CallBack = function()
        self:OnBtnView()
    end

    self.DormitoryDrop.onValueChanged:AddListener(function()
        self:OnDormitoryDropClick()
    end)

    self.BtnAllCollectionShow.CallBack = function()
        self:OnBtnAllCollectionShow()
    end

    self.BtnCharUnfold.CallBack = function()
        self:OnBtnCharUnfold()
    end
    self.BtnDisplayUnfold.CallBack = function()
        self:OnBtnDisplayUnfold()
    end
    self.BtnCollectionUnfold.CallBack = function()
        self:OnBtnCollectionUnfold()
    end
end

function XUiPanelSetting:OnBtnCollectionUnfold()
    local isUnfold
    if self.BtnCollectionUnfold.ButtonState == CS.UiButtonState.Select then
        isUnfold = 1
        self.PanelCollectionWall.gameObject:SetActiveEx(true)
    else
        isUnfold = 2
        self.PanelCollectionWall.gameObject:SetActiveEx(false)
    end

    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "CollectionUnfold"), isUnfold)
end

function XUiPanelSetting:OnBtnDisplayUnfold()
    local isUnfold = self.BtnDisplayUnfold.ButtonState == CS.UiButtonState.Select

    self.PanelDisplaySetting.gameObject:SetActiveEx(isUnfold)
    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "DisplayUnfold"), isUnfold)
end

function XUiPanelSetting:OnBtnCharUnfold()
    local isUnfold = self.BtnCharUnfold.ButtonState == CS.UiButtonState.Select
    local isShowAllCharacter = self.CurCharactersAppearanceType and self.CurCharactersAppearanceType == XPlayerInfoConfigs.CharactersAppearanceType.All or false

    self.PanelMember.gameObject:SetActiveEx(isUnfold)

    -- 展示全角色不显示头像
    self.MemberContent.gameObject:SetActiveEx(not isShowAllCharacter)
    self.HadAllChar.gameObject:SetActiveEx(isShowAllCharacter)
    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "CharUnfold"), isUnfold)
end

function XUiPanelSetting:OnBtnAllCollectionShow()
    local isShowAll = self.BtnAllCollectionShow.ButtonState == UiButtonState.Select
    for _, wall in pairs(self.UseWallDic) do
        wall:SetIsSelect(isShowAll)
    end
end

function XUiPanelSetting:OnBtnAllCharacterShow()
    local isShowAll = self.BtnAllCharacterShow.ButtonState == UiButtonState.Select

    if isShowAll then
        self.CurCharactersAppearanceType = XPlayerInfoConfigs.CharactersAppearanceType.All
    else
        self.CurCharactersAppearanceType = XPlayerInfoConfigs.CharactersAppearanceType.Select
    end
    self.MemberContent.gameObject:SetActiveEx(not isShowAll)
    self.HadAllChar.gameObject:SetActiveEx(isShowAll)

    self:CheckSave()
end

function XUiPanelSetting:OnBtnCharacter(index)
    local curTeam = {}
    for i = 1, MAX_CHARACTER do
        curTeam[i] = self.CharacterList[i] or 0
    end

    local cb = function(resTeam)
        self.CharacterList = {}
        for i = 1, #resTeam do
            if resTeam[i] ~= 0 then
                table.insert(self.CharacterList, resTeam[i])
            end
        end
        self.UiRoot.CharacterList = self.CharacterList
        self:CheckSave()
        self:UpdateCharacterHead()
    end

    -- 根据选中的角色类型打开对应的页签
    local characterType
    if curTeam[index] and curTeam[index] ~= 0 then
        characterType = XMVCA.XCharacter:GetCharacterType(curTeam[index])
    else
        -- 添加新角色时，默认打开构造体页签
        characterType = XCharacterConfigs.CharacterType.Normal
    end

    -- 角色展示不拦截角色类型，构造体与授格者可以同时展示
    XLuaUiManager.Open("UiRoomCharacter", curTeam, index, cb, nil, nil, { NotReset = true, SelectCharacterType = characterType })
end

function XUiPanelSetting:OnBtnBabelScoreTitleShow()
    local state = self.CurScoreTitleShowState[ScoreTitleType.Babel]
    if state then
        state.Hide = (self.BtnBabelScoreTitleShow.ButtonState == UiButtonState.Select) and
                XMedalConfigs.Hide.OFF or
                XMedalConfigs.Hide.ON
    else
        self.BtnBabelScoreTitleShow:SetButtonState(UiButtonState.Normal)
    end
    self:CheckSave()
end

function XUiPanelSetting:OnBtnSave()
    self.UiRoot.NeedSave = false
    self:SaveScoreTitleShowData()
    self:SaveCollectionWallShow()
    XDataCenter.PlayerInfoManager.SaveData(self.CurCharactersAppearanceType, self.CharacterList, self.CurAppearanceSetting, function()
        self.CurCharactersAppearanceType = XPlayer.GetAppearanceShowType()
        self.OldCharactersAppearanceType = XPlayer.GetAppearanceShowType()
        self.OldAppearanceSetting = XPlayer.GetAppearanceSettingInfo()
        self.CurAppearanceSetting = XPlayer.GetAppearanceSettingInfo()
    end)
end

---
--- 展示预览
function XUiPanelSetting:OnBtnView()
    XDataCenter.PlayerInfoManager.RequestPlayerInfoData(XPlayer.Id, function(data)
        XPlayer.SetPlayerLikes(data.Likes)
        local tmpData = {}
        for k, v in pairs(data) do
            tmpData[k] = v
        end
        if data.Id == XPlayer.Id then
            tmpData.AchievementDetail.Achievement = XDataCenter.AchievementManager.GetAchievementCompleteCount()
            tmpData.AchievementDetail.TotalAchievement = XDataCenter.AchievementManager.GetTotalAchievementCount()   
        end
        tmpData.AppearanceSettingInfo = self.CurAppearanceSetting

        if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Dorm) then
            local dormDetail = {}
            dormDetail.DormitoryId = self.CurAppearanceSetting.DormitoryId
            for _, dorm in pairs(self.SortedDormitoryList) do
                if dorm.DormitoryId == dormDetail.DormitoryId then
                    dormDetail.DormitoryName = dorm.DormitoryName
                end
            end
            if not dormDetail.DormitoryName then
                XLog.Error(string.format("XUiPanelSetting:OnBtnView函数错误，在self.SortedDormitoryList中没有宿舍%s的数据", dormDetail.DormitoryId))
                dormDetail = nil
            end
            tmpData.DormDetail = dormDetail
        end

        --展示角色列表
        tmpData.CharacterShow = {}
        if self.CurCharactersAppearanceType == XPlayerInfoConfigs.CharactersAppearanceType.Select then
            for i = 1, MAX_CHARACTER do
                if self.CharacterList[i] then
                    local char = XDataCenter.CharacterManager.GetCharacter(self.CharacterList[i])
                    tmpData.CharacterShow[i] = char
                else
                    tmpData.CharacterShow[i] = nil
                end
            end
        else
            --展示全角色
            tmpData.CharacterShow = XDataCenter.CharacterManager.GetOwnCharacterList()
        end

        --请求的数据有缓冲，使用XPlayer的数据可以实时看到预览的改变
        tmpData.Sign = XPlayer.Sign
        tmpData.Level = XPlayer.Level
        tmpData.Likes = XPlayer.Likes
        tmpData.Birthday = XPlayer.Birthday
        tmpData.CurrHeadFrameId = XPlayer.CurrHeadFrameId
        tmpData.CurrHeadPortraitId = XPlayer.CurrHeadPortraitId
        tmpData.AppearanceShowType = self.CurCharactersAppearanceType   --角色展示类型

        --收藏品信息
        tmpData.CollectionShow = {}
        for _, v in pairs(XDataCenter.MedalManager.GetScoreTitleUnLockList()) do
            table.insert(tmpData.CollectionShow, v)
        end

        tmpData.CollectionWall = {}
        for wallId, isShow in pairs(self.CurWallShowSetting) do
            if isShow then
                local wallData = XDataCenter.CollectionWallManager.GetWallEntityData(wallId)
                tableInsert(tmpData.CollectionWall, wallData)
            end
        end

        --成员涂装
        tmpData.FashionShow = {}
        for k, _ in pairs(XDataCenter.FashionManager.GetOwnFashionDataDic()) do
            table.insert(tmpData.FashionShow, k)
        end

        --武器涂装
        tmpData.WeaponFashionShow = {}
        for _, v in pairs(XDataCenter.WeaponFashionManager.GetOwnWeaponFashion()) do
            table.insert(tmpData.WeaponFashionShow, v.Id)
        end
        tmpData.CurrentWearNameplate = data.CurrentWearNameplate

        XLuaUiManager.Open("UiPlayerInfo", tmpData, nil, true)
    end)
end

function XUiPanelSetting:OnDormitoryDropClick()
    -- 选择的宿舍Id与当前设置的Id是否相同
    local selectDormId = self.SortedDormitoryList[self.DormitoryDrop.value + 1].DormitoryId

    if selectDormId == self.CurAppearanceSetting.DormitoryId then
        return
    end
    self.CurAppearanceSetting.DormitoryId = selectDormId
    self:CheckSave()
end

---
--- 'wallDataId'墙的展示设置缓存更改为'isShow'
--- 由XUiGridCollectionWall脚本的点击函数回调
---@param wallDataId number
---@param isShow boolean
function XUiPanelSetting:ChangeCurShowSetting(wallDataId, isShow)
    local isShowAll = true

    if self.CurWallShowSetting[wallDataId] ~= nil then
        self.CurWallShowSetting[wallDataId] = isShow
        self:CheckSave()
    else
        XLog.Error(string.format("XUiPanelSetting:ChangeCurShowSetting函数错误，没有Id:%s 收藏品墙数据", tostring(wallDataId)))
    end

    for _, showSetting in pairs(self.CurWallShowSetting) do
        if showSetting == false then
            isShowAll = false
            break;
        end
    end

    if isShowAll then
        self.BtnAllCollectionShow:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnAllCollectionShow:SetButtonState(CS.UiButtonState.Normal)
    end
end


--------------------------------------------------初始化展示设置的按钮组----------------------------------------------------------

---
--- 宿舍展示
function XUiPanelSetting:InitDormitoryShowBtnGroup()
    self.DormitoryShowBtns = { self.BtnDormitoryShowAll, self.BtnDormitoryShowFriend, self.BtnDormitoryShowSelf }
    self.DormitoryShowBtnGroup:Init(self.DormitoryShowBtns, function(tabIndex)
        self:OnDormitoryShowBtnGroup(tabIndex)
    end)
end
function XUiPanelSetting:OnDormitoryShowBtnGroup(tabIndex)
    if self.DormitoryShowIndex and self.DormitoryShowIndex == tabIndex then
        return
    end
    self.CurAppearanceSetting.DormitoryType = tabIndex
    self.DormitoryShowIndex = tabIndex
    self:CheckSave()
end

---
--- 成员展示
function XUiPanelSetting:InitMemberShowBtnGroup()
    self.MemberShowBtns = { self.BtnMemberShowAll, self.BtnMemberShowFriend, self.BtnMemberShowSelf }
    self.MemberShowBtnGroup:Init(self.MemberShowBtns, function(tabIndex)
        self:OnMemberShowBtnGroup(tabIndex)
    end)
end
function XUiPanelSetting:OnMemberShowBtnGroup(tabIndex)
    if self.MemberShowIndex and self.MemberShowIndex == tabIndex then
        return
    end
    self.CurAppearanceSetting.CharacterType = tabIndex
    self.MemberShowIndex = tabIndex
    self:CheckSave()
end

---
--- 收藏品展示
function XUiPanelSetting:InitCollectionShowBtnGroup()
    self.CollectionShowBtns = { self.BtnCollectionShowAll, self.BtnCollectionShowFriend, self.BtnCollectionShowSelf }
    self.CollectionShowBtnGroup:Init(self.CollectionShowBtns, function(tabIndex)
        self:OnCollectionShowBtnGroup(tabIndex)
    end)
end
function XUiPanelSetting:OnCollectionShowBtnGroup(tabIndex)
    if self.CollectionShowIndex and self.CollectionShowIndex == tabIndex then
        return
    end
    self.CurAppearanceSetting.TitleType = tabIndex
    self.CollectionShowIndex = tabIndex
    self:CheckSave()
end

---
--- 成员涂装展示
function XUiPanelSetting:InitFashionShowBtnGroup()
    self.FashionShowBtns = { self.BtnFashionShowAll, self.BtnFashionShowFriend, self.BtnFashionShowSelf }
    self.FashionShowBtnGroup:Init(self.FashionShowBtns, function(tabIndex)
        self:OnFashionShowBtnGroup(tabIndex)
    end)
end
function XUiPanelSetting:OnFashionShowBtnGroup(tabIndex)
    if self.FashionShowIndex and self.FashionShowIndex == tabIndex then
        return
    end
    self.CurAppearanceSetting.FashionType = tabIndex
    self.FashionShowIndex = tabIndex
    self:CheckSave()
end

---
--- 武器涂装展示
function XUiPanelSetting:InitWeaponShowBtnGroup()
    self.WeaponShowBtns = { self.BtnWeaponShowAll, self.BtnWeaponShowFriend, self.BtnWeaponShowSelf }
    self.WeaponShowBtnGroup:Init(self.WeaponShowBtns, function(tabIndex)
        self:OnWeaponShowBtnGroup(tabIndex)
    end)
end
function XUiPanelSetting:OnWeaponShowBtnGroup(tabIndex)
    if self.WeaponShowIndex and self.WeaponShowIndex == tabIndex then
        return
    end
    self.CurAppearanceSetting.WeaponFashionType = tabIndex
    self.WeaponShowIndex = tabIndex
    self:CheckSave()
end