*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.HTTP
Library             RPA.RobotLogListener
Library             OperatingSystem
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs

*** Variables ***
${orders_pdf}    ${CURDIR}${/}orders_pdf


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    2x    5s    Preview the robot
        Wait Until Keyword Succeeds    2x    5s    Submit the order
        Check if danger is present
        Store the receipt as a PDF file    Order_${row}[Order number]
        Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]    Order_${row}[Order number]    Order_${row}[Order number]
        Go to order another robot
    END
    Sleep    5s
    Get and say my name
    [Teardown]    Close the browser
    Create a ZIP file of the receipts
    Ask if user want to keep pdf Folder


*** Keywords ***
Disable Screenshots On Error
         

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK
    

Get Orders
    Download   https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${csv_data}=    Read table from CSV    orders.csv
    RETURN    ${csv_data}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Check if danger is present
    Wait Until Keyword Succeeds    2x    5s    Check if danger is present

Store the receipt as a PDF file
    Repeat Keyword    10x    Check if danger is present
    [Arguments]    ${pdf_name}
    
    Wait Until Element Is Visible    id:receipt
       
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${orders_pdf}${/}${pdf_name}.pdf

Take a screenshot of the robot
    Wait Until Element Is Visible    id:robot-preview-image    timeout=10s
    [Arguments]    ${robot_screenshot}
    Screenshot    id:robot-preview-image    ${orders_pdf}${/}${robot_screenshot}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${robot_screenshot}    ${pdf_name}    ${output_pdf}
    Add Watermark Image To Pdf   ${orders_pdf}${/}${robot_screenshot}.png    ${orders_pdf}${/}${pdf_name}.pdf    ${orders_pdf}${/}${output_pdf}.pdf
    Remove File    ${orders_pdf}${/}${robot_screenshot}.png 

Go to order another robot
    Click Button    order-another

Close the browser
    Close Browser

Check if danger is present 
    ${danger_present}=    Is Element Visible    css:div.alert-danger
    Run Keyword If    ${danger_present}    Click Button    order

Create a ZIP file of the receipts
    Archive Folder With Zip    ${orders_pdf}    orders_reciepts.zip    recursive=True 

Get and Say my name 
    ${secret}=    Get Secret    credentials 
    Log   ${secret}[username]

Ask if user want to keep pdf Folder 
    Add icon      Warning
    Add heading   Delete orders_pdf folder and keep orders_reciepts zip ?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        Log    ${result}
        Empty Directory    orders_pdf
        Remove Directory    orders_pdf
    END 
