local this = {}

function this.Init(go)
    this.GameObject = go
    this.Transform = go.transform
    XTool.InitUiObject(this)
    this.GridLogLow.gameObject:SetActiveEx(false)
    this.Pools = {}
    for i = 1, 10 do
        local item = {}
        item.GameObject = CS.UnityEngine.Object.Instantiate(this.GridLogLow.gameObject)
        item.Transform = item.GameObject.transform
        XTool.InitUiObject(item)
        item.Transform:SetParent(this.PanelContent, false)
        item.GameObject:SetActiveEx(false)
        this.Pools[i] = item
    end
end

function this.Refresh()
    local records = XDataCenter.FireworksManager.GetRecords()
    for i = 1, #records do
        local name, info, time = XDataCenter.FireworksManager.GetRecordString(records[i])
        this.Pools[i].TxtName.text = name
        this.Pools[i].TxtItems.text = info
        this.Pools[i].TxtTime.text = time
        this.Pools[i].GameObject:SetActiveEx(true)
    end

    for i = #records + 1, #this.Pools do
        this.Pools[i].GameObject:SetActiveEx(false)
    end
end

function this.Show()
    this.GameObject:SetActiveEx(true)
end

function this.Hide()
    this.GameObject:SetActiveEx(false)
end

return this