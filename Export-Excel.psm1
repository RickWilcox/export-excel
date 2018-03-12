Function Export-Excel {
    <#
        .SYNOPSIS
            Accepts input of a PSObject collection of items and an Excel Object to create a worksheet 
            and populate it with the contents of the collection.
        .DESCRIPTION
            This module was created to aid in writing from a PowerShell script to an Excel Spreadsheet. 
        .NOTES
            Filename: Export-Excel.psm1
            Author: Rick Wilcox 
            Requirements: PSObject, Microsoft Excel installed and availble COM object (YMMV), rights to write to the location of the workbook
        .PARAMETER  PSOTable
            Mandaotry PSObject that will be written to the spreadsheet with headers and rows.
        .PARAMETER  WorkbookPath
            Mandatory string that contains the path to either and existing Excel workbook or the path to which the new workbook will be saved. 
        .PARAMETER  SheetName
            Non-mandatory string that will become the title of the sheet that is to be created. If the sheet already exists, the sheet will created with an index number at the end.
        .PARAMETER  MaxColumnWidth
            Non-mandatory value that will create columns at the width provided.
        .PARAMETER  selectionMode
            Input Info
        .EXAMPLE
            Input Info
        .OUTPUTS
            Input Info
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeLine = $True)]
        [PSObject]$PSOTable,


        [Parameter(Mandatory = $True)]
        [String]$WorkbookPath,


        [Parameter(Mandatory = $False)]
        [String]$SheetName,


        [Parameter(Mandatory = $False)]
        [Int32]$MaxColumnWidth = 50
    )
    Begin {
        Try {
            #------- Initialize Excel COM object and workbook --------
            Add-Type -AssemblyName Microsoft.Office.Interop.Excel
            $excel = New-Object -ComObject excel.application 
            #$excel.visible = $True    
            Try {
                $workBook = $Excel.Workbooks.Open($WorkbookPath)
            }
            Catch {
                Write-Debug "Unable to open existing workbook, it likely does not exist."
            }
            If (!$workBook) {
                $newWorkbook = $True
                $workBook = $excel.Workbooks.Add() 
                $workSheet = $workBook.Worksheets.item(1)
                if ($SheetName) {
                    $workSheet.name = $SheetName
                }
            }
            #-------- Add worksheet and format cells as text --------
            if (!$newWorkBook) {
                $WorkSheet = $workBook.Worksheets | Where-Object {$_.name -like $sheetName}
                if ($workSheet) {
                    $Excel.DisplayAlerts = $False
                    $workSheetTemp = $workBook.Worksheets.add()
                    $workSheet.delete()
                    $Excel.DisplayAlerts = $True
                }
                $workSheet = $workBook.Worksheets.add()
                $workSheet.name = $SheetName
                if ($workSheetTemp) {
                    $workSheetTemp.delete()
                }
            }
            #------- Set the worksheet cells format -------
            $workSheet.Cells.NumberFormat = "@"
            $range = $workSheet.Cells
            $range.clear
        }
        Catch{
            If(!$workBook){
                Write-Host "Unable to create Excel workbook object" -ForegroundColor Red
                Break
            }
            Write-Host $_.invocationinfo.positionmessage -ForegroundColor Red
            Write-Host $_ -ForegroundColor Red
        }
    }
    Process {
        #------- Set headers --------
        $headers = $PSOTable[0].PSObject.Properties.Name
        $headers | ForEach-Object {
            $workSheet.Cells.Item(1,($headers.indexof($_)) + 1) = $_
        } 
        #-------- Format Worksheet Table ---------
        $ListObject = $workSheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::xlSrcRange, $WorkSheet.UsedRange, $null ,[Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $listObject.Name = "Table1"
        $listObject.TableStyle = "TableStyleLight17"
        #--------- write collection to worksheet -------
        $PSOTable | ForEach-Object{
            ForEach($header in $headers){$workSheet.Cells.Item(($PSOTable.indexof($_)) + 2,($headers.indexof($header)) + 1) = ($_."$($header)") -join "`n"}
        } 
        $usedRange = $worksheet.UsedRange
        $usedRange.Cells.Font.Size = 9
        $usedrange.WrapText = $True
        $usedRange.HorizontalAlignment = [Microsoft.Office.Interop.Excel.XlHAlign]::xlHAlignLeft.value__
        $usedRange.VerticalAlignment = [Microsoft.Office.Interop.Excel.XlVAlign]::xlVAlignTop.value__
        $usedRange.EntireColumn.ColumnWidth = 70
        $x = $usedRange.EntireColumn.Autofit()
        $x = $usedRange.EntireRow.Autofit()
        $headers | ForEach-Object{$workSheet.Cells.Item(1,($headers.indexof($_)) + 1).Font.Size = 10} 
        ForEach($column in $workSheet.UsedRange.EntireColumn){
            If($column.ColumnWidth -gt $MaxColumnWidth){$column.ColumnWidth = $MaxColumnWidth}
        }
    }
    end {
        $Excel.DisplayAlerts = $False
        If($newWorkbook){
            $workBook.SaveAs($WorkbookPath)
            $workbook.close()
        }Else{
            $workBook.Save()
            $workbook.close()
        }
        $excel.Workbooks.close()
        $Excel.DisplayAlerts = $True
        $Excel.Quit()    
        
        #$excel.visible = $True
        # Cleanup
        $x = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
        Remove-Variable excel
    }    
}

