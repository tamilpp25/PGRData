local XUiGridArchiveMonster = require("XUi/XUiArchive/XUiGridArchiveMonster")
local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiArchiveMonster = XLuaUiManager.Register(XLuaUi, "UiArchiveMonster")

function XUiArchiveMonster:OnEnable()
    --self:SetupDynamicTable(self.CurType)
    self:DynamicTableDataSync()
end

function XUiArchiveMonster:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:Init()
    self:InitNewTag()
    self:InitRedPoint()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchiveMonster:OnDestroy()
    local datas = self._Control:GetArchiveMonsterList()
    self._Control:ClearMonsterNewTag(datas)
    self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Info, datas)
    self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Setting, datas)
    self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Skill, datas)
end

function XUiArchiveMonster:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchiveMonsterList)
    self.DynamicTable:SetProxy(XUiGridArchiveMonster,self)
    self.DynamicTable:SetDelegate(self)
    self.GridArchiveMonster.gameObject:SetActiveEx(false)
end

function XUiArchiveMonster:SetupDynamicTable(type)
    self.PageDatas = self._Control:GetArchiveMonsterList(type)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveMonster:DynamicTableDataSync()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveMonster:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas, self, index)
    end
end

function XUiArchiveMonster:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchiveMonster:Init()
    self.CurType = 1
    self.BtnList = {
        [1] = self.BtnFirst1,
        [2] = self.BtnFirst2,
        [3] = self.BtnFirst3
    }

    self.TypeList = {
        [1] = XEnumConst.Archive.MonsterType.Pawn,
        [2] = XEnumConst.Archive.MonsterType.Elite,
        [3] = XEnumConst.Archive.MonsterType.Boss
    }

    self.BtnContent:Init(self.BtnList, function(index) self:SelectType(index) end)
    self.BtnContent:SelectIndex(self.CurType)
end

function XUiArchiveMonster:InitRedPoint()
    self:AddRedPointEvent(self.BtnFirst1,
        self.OnCheckPawnRedPoint, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_RED },
        XEnumConst.Archive.MonsterType.Pawn)
    self:AddRedPointEvent(self.BtnFirst2,
        self.OnCheckEliteRedPoint, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_RED },
        XEnumConst.Archive.MonsterType.Elite)
    self:AddRedPointEvent(self.BtnFirst3,
        self.OnCheckBossRedPoint, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_RED },
        XEnumConst.Archive.MonsterType.Boss)
end

function XUiArchiveMonster:InitNewTag()
    self:AddRedPointEvent(self.BtnFirst1.TagObj,
        self.OnCheckPawnTag, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_TAG },
        XEnumConst.Archive.MonsterType.Pawn)
    self:AddRedPointEvent(self.BtnFirst2.TagObj,
        self.OnCheckEliteTag, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_TAG },
        XEnumConst.Archive.MonsterType.Elite)
    self:AddRedPointEvent(self.BtnFirst3.TagObj,
        self.OnCheckBossTag, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_TYPE_TAG },
        XEnumConst.Archive.MonsterType.Boss)
end

function XUiArchiveMonster:SelectType(index)

    self.CurType = index

    self:SetupDynamicTable(self.TypeList[index])
    self.RateNum.text = string.format("%d%s", self._Control:GetMonsterCompletionRate(self.TypeList[index]), "%")
    self:PlayAnimation("QieHuan")

    if self.OldType then
        local datas = self._Control:GetArchiveMonsterList(self.TypeList[self.OldType])
        self._Control:ClearMonsterNewTag(datas)
        self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Info, datas)
        self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Setting, datas)
        self._Control:ClearDetailRedPoint(XEnumConst.Archive.MonsterDetailType.Skill, datas)
    end

    self.OldType = index
end

function XUiArchiveMonster:OnBtnBackClick()
    self:Close()
end

function XUiArchiveMonster:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveMonster:OnCheckPawnRedPoint(count)
    if self.BtnFirst1 then
        self.BtnFirst1:ShowReddot(count >= 0)
    end
end

function XUiArchiveMonster:OnCheckEliteRedPoint(count)
    if self.BtnFirst2 then
        self.BtnFirst2:ShowReddot(count >= 0)
    end
end

function XUiArchiveMonster:OnCheckBossRedPoint(count)
    if self.BtnFirst3 then
        self.BtnFirst3:ShowReddot(count >= 0)
    end
end

function XUiArchiveMonster:OnCheckPawnTag(count)
    if self.BtnFirst1 then
        self.BtnFirst1:ShowTag(count >= 0)
    end
end

function XUiArchiveMonster:OnCheckEliteTag(count)
    if self.BtnFirst2 then
        self.BtnFirst2:ShowTag(count >= 0)
    end
end

function XUiArchiveMonster:OnCheckBossTag(count)
    if self.BtnFirst3 then
        self.BtnFirst3:ShowTag(count >= 0)
    end
end