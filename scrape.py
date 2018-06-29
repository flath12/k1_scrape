import pdfquery
import collections
    
def gen_data(path,pages):
    pdf = pdfquery.PDFQuery(path)
    pdf.load(pages["main_page"][0]-1)
    data = {"year" : get_cy(pdf),
            "fund_ein" : get_fund_ein(pdf),
            "fund_name" : get_fund_name(pdf),
            "partner_ein" : get_partner_ein(pdf),
            "beginning_ca" : get_beginning_ca(pdf),
            "capital_cont" : get_cap_contr(pdf),
            "cy_increase" : get_cy_increase(pdf),
            "withdrawls" : get_withdrawals(pdf),
            "ending_ca" : get_ending_ca(pdf),
            }
    box_data = get_box_detail(pdf)
    data.update(box_data)
    return data

def get_cy(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("For calendar year")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner, bottom_corner)).text()
    text = text.split("year")[1].split(",")[0].lstrip()
    return text
    
def get_fund_ein(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("employer identification number")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner - 0, bottom_corner-10, left_corner+150, bottom_corner)).text()
    text = text.split("number")[1].lstrip()
    return text

def get_partner_ein(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("identifying number")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner - 0, bottom_corner-10, left_corner+0, bottom_corner)).text()
    text = text.split("number")[1].split("#")[0].lstrip()
    return text
    
def get_fund_name(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("name, address, city, state, and ZIP code")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner - 0, bottom_corner-15, left_corner+200, bottom_corner)).text()
    text = text.split("code")[1].lstrip()
    return text

def get_beginning_ca(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Beginning capital account")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner + 300, bottom_corner+10)).text()
    text = clean_box_data_results(text)
    return text

def get_cap_contr(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Capital contributed during the year")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner + 300, bottom_corner+10)).text()
    text = clean_box_data_results(text)
    return text

def get_cy_increase(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Current year increase (decrease)")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner + 300, bottom_corner+10)).text()
    text = clean_box_data_results(text)
    return text

def get_withdrawals(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Withdrawals & distributions")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner + 300, bottom_corner+10)).text()
    text = clean_box_data_results(text)
    return text

def get_ending_ca(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Ending capital account")')
    left_corner = float(label.attr('x0'))
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (left_corner, bottom_corner, left_corner + 300, bottom_corner+10)).text()
    text = text.replace(',', '')
    text = float([s for s in text.split() if s.isdigit()][0])
    return text

def clean_box_data_results(text):
    text = text.lstrip()
    negative = False
    if "-" in text or "(" in text and ")" in text:
        negative = True
        text = text.replace('-', '').replace('(', '').replace(')', '')
    any_numbers = any(char.isdigit() for char in text)
    if text is None or text == "*L" or text == "" or not any_numbers:
        text = 0.0
    else:
        text = text.replace(',', '')
        text = float([s for s in text.split() if s.isdigit()][0])
    if negative:
        text = text * -1.0
    return text

def get_one_box_data_by_label(pdf,label_string,x_1,x_2):
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner-10, x_2-5, bottom_corner-5)).text()
    text = clean_box_data_results(text)
    return text
    
def box_1_data(pdf,x_1,x_2):
    label_string = "Ordinary business income (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_2_data(pdf,x_1,x_2):
    label_string = "Net rental real estate income (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_3_data(pdf,x_1,x_2):
    label_string = "Other net rental income (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data
    
def box_4_data(pdf,x_1,x_2):
    label_string = "Guaranteed payments"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_5_data(pdf,x_1,x_2):
    label_string = "Interest income"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_6a_data(pdf,x_1,x_2):
    label_string = "Ordinary dividends"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_6b_data(pdf,x_1,x_2):
    label_string = "Qualified dividends"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_7_data(pdf,x_1,x_2):
    label_string = "Royalties"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_8_data(pdf,x_1,x_2):
    label_string = "Net short-term capital gain (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_9a_data(pdf,x_1,x_2):
    label_string = "Net long-term capital gain (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data
    
def box_9b_data(pdf,x_1,x_2):
    label_string = "Collectibles (28%) gain (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_9c_data(pdf,x_1,x_2):
    label_string = "Unrecaptured section 1250 gain"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_10_data(pdf,x_1,x_2):
    label_string = "Net section 1231 gain (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_11_1_data(pdf,x_1,x_2):
    label_string = "Other income (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data

def box_11_2_data(pdf,x_1,x_2):
    label_string = "Other income (loss)"
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    label_string_of_next_box = "Section 179 deduction"
    label_of_next_box = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string_of_next_box)
    bottom_corner_of_next_box = float(label_of_next_box.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner_of_next_box+10, x_2-5, bottom_corner-5)).text()
    text = text.split(" ")
    text = [t for t in text if t == "STMT" or t.isdigit()]
    if len(text) > 1:
        text = text[1]
        text = clean_box_data_results(text)
    else:
        text = 0.0
    return text

def box_11_3_data(pdf,x_1,x_2):
    label_string = "Other income (loss)"
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    label_string_of_next_box = "Section 179 deduction"
    label_of_next_box = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string_of_next_box)
    bottom_corner_of_next_box = float(label_of_next_box.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner_of_next_box+10, x_2-5, bottom_corner-5)).text()
    text = text.split(" ")
    text = [t for t in text if t == "STMT" or t.isdigit()]
    if len(text) > 2:
        text = text[2]
        text = clean_box_data_results(text)
    else:
        text = 0.0
    return text

def box_12_data(pdf,x_1,x_2):
    label_string = "Section 179 deduction"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data * -1.0

def box_13_1_data(pdf,x_1,x_2):
    label_string = "Other deductions"
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    label_string_of_next_box = "Self-employment earnings (loss)"
    label_of_next_box = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string_of_next_box)
    bottom_corner_of_next_box = float(label_of_next_box.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner_of_next_box+10, x_2-5, bottom_corner-5)).text()
    text = text.split(" ")
    text = [t for t in text if t == "STMT" or t.isdigit()]
    if len(text) > 0:
        text = text[0]
        if text == "STMT":
            text = "STMT"
        else:
            text = clean_box_data_results(text) * -1.0
    else:
        text = 0.0
    return text

def box_13_2_data(pdf,x_1,x_2):
    label_string = "Other deductions"
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    label_string_of_next_box = "Self-employment earnings (loss)"
    label_of_next_box = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string_of_next_box)
    bottom_corner_of_next_box = float(label_of_next_box.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner_of_next_box+10, x_2-5, bottom_corner-5)).text()
    text = text.split(" ")
    text = [t for t in text if t == "STMT" or t.isdigit()]
    if len(text) > 1:
        text = text[1]
        if text == "STMT":
            text = "STMT"
        else:
            text = clean_box_data_results(text) * -1.0
    else:
        text = 0.0
    return text

def box_13_3_data(pdf,x_1,x_2):
    label_string = "Other deductions"
    label = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string)
    bottom_corner = float(label.attr('y0'))
    label_string_of_next_box = "Self-employment earnings (loss)"
    label_of_next_box = pdf.pq('LTTextLineHorizontal:contains("%s")' % label_string_of_next_box)
    bottom_corner_of_next_box = float(label_of_next_box.attr('y0'))
    text = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x_1, bottom_corner_of_next_box+10, x_2-5, bottom_corner-5)).text()
    text = text.split(" ")
    text = [t for t in text if t == "STMT" or t.isdigit()]
    if len(text) > 2:
        text = text[2]
        if text == "STMT":
            text = "STMT"
        else:
            text = clean_box_data_results(text) * -1.0
    else:
        text = 0.0
    return text

def box_14_data(pdf,x_1,x_2):
    label_string = "Self-employment earnings (loss)"
    data = get_one_box_data_by_label(pdf,label_string,x_1,x_2)
    return data
    
def location_of_detail_left_edge(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("Ordinary business income (loss)")')
    x = label.attr('x0')
    return float(x)
    
def location_of_detail_middle_edge(pdf):
    label = pdf.pq('LTTextLineHorizontal:contains("15 Credits")')
    x = label.attr('x0')
    return float(x)

def get_box_detail(pdf):
    x_1 = location_of_detail_left_edge(pdf)
    x_2 = location_of_detail_middle_edge(pdf)
    box_data = {"box_1" : box_1_data(pdf,x_1,x_2),
                "box_2" : box_2_data(pdf,x_1,x_2),
                "box_3" : box_3_data(pdf,x_1,x_2),
                "box_4" : box_4_data(pdf,x_1,x_2),
                "box_5" : box_5_data(pdf,x_1,x_2),
                "box_6a" : box_6a_data(pdf,x_1,x_2),
                "box_6b" : box_6b_data(pdf,x_1,x_2),
                "box_7" : box_7_data(pdf,x_1,x_2),
                "box_8" : box_8_data(pdf,x_1,x_2),
                "box_9a" : box_9a_data(pdf,x_1,x_2),
                "box_9b" : box_9b_data(pdf,x_1,x_2),
                "box_9c" : box_9c_data(pdf,x_1,x_2),
                "box_10" : box_10_data(pdf,x_1,x_2),
                "box_11_1" : box_11_1_data(pdf,x_1,x_2),
                "box_11_2" : box_11_2_data(pdf,x_1,x_2),
                "box_11_3" : box_11_3_data(pdf,x_1,x_2),
                "box_13_1" : box_13_1_data(pdf,x_1,x_2),
                "box_13_2" : box_13_2_data(pdf,x_1,x_2),
                "box_13_3" : box_13_3_data(pdf,x_1,x_2),
                "box_14" : box_14_data(pdf,x_1,x_2),
        }
    return box_data

def boxes_with_stmt_data(pdf,box_data):
    data = {}
    for i in box_data:
        if box_data[i] == "STMT":
            sub_box_values = []
            for n in range(3):
                sub_cell = i[:-2] + "_" + str(n + 1)
                value = box_data[sub_cell]
                sub_box_values.append(value)
            sub_box_values = [b for b in sub_box_values if b != "STMT"]
            data[i[:-2]] = sub_box_values
    return data

def page_numbers(path):
    pdf = pdfquery.PDFQuery(path)
    pdf.load()
    pages = {}
    main_page = pdf.pq('LTTextLineHorizontal:contains("Information About the Partnership")')
    for pq in main_page:
        page_pq = pq.iterancestors('LTPage').next()   # Use just the first ancestor
        pages["main_page"] = [page_pq.layout.pageid,main_page.attr('x0'),main_page.attr('y0'),main_page.attr('x1'),main_page.attr('y1')]
    item_l = pdf.pq('LTTextLineHorizontal:contains("PER SCHEDULE K-1")')
    for pq in item_l:
        page_pq = pq.iterancestors('LTPage').next()   # Use just the first ancestor
        pages["Item_L_detail"] = [page_pq.layout.pageid,item_l.attr('x0'),item_l.attr('y0'),item_l.attr('x1'),item_l.attr('y1')]
    line_11 = pdf.pq('LTTextLineHorizontal:contains("LINE 11 - ")')
    for pq in line_11:
        page_pq = pq.iterancestors('LTPage').next()   # Use just the first ancestor
        pages["Item_11_detail"] = [page_pq.layout.pageid,line_11.attr('x0'),line_11.attr('y0'),item_l.attr('x1'),item_l.attr('y1')]
    return pages

path = "k1_3.pdf"
pages = page_numbers(path)
print(pages)
data = gen_data(path,pages)
print(data)



