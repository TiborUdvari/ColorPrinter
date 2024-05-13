// This sketch constantly monitor the downloads folder and when a new file is added, check if matches the pattern ("date time palette 012 234 567 890.svc,
// it will be copied to the specified folder, then
// a pdf will be created and saved in the same folder with the same name as the palette.svg file, then printed.

import processing.pdf.*;


String palettesFolder = "/Users/pierre.rossel/Downloads/";
String archivesFolder;

// Page size
float cm = 72 / 2.54; // Convert cm to pix at 72 DPI
int pageWidth = round(14.8 * cm);
int pageHeight = round(21.1 * cm);

PShape shape;
PShape shapeLogo;

PGraphics pgPreview; // One graphics for preview

String paletteFilename;

PFont fontTitle;
PFont fontText;

JSONObject luminance;

void settings() {
    size(pageWidth, pageHeight);
}

void setup() {
    //size(pageWidth, pageHeight);
    
    background(255);
    println(archivesFolder);
    
    archivesFolder = sketchPath("archives/");
    
    //Verify if archives folder exists and create it if it doesn't
    File folder = new File(archivesFolder);
    if (!folder.exists()) {
        folder.mkdir();
        println(folder.toPath());
    }
    
    //load svg file 2024-05-13 185455 Palette 350 070.svg
    //shape = loadShape(palettesFolder + "2024-05-13 185455 Palette 350 070.svg");
    //shape = loadShape(palettesFolder + "Hexagone2.svg");
    //shape = loadShape(palettesFolder + "2024-05-13 200254 Palette 069 220 171 162.svg");
    //shape = loadShape(palettesFolder + "2024-05-13 202302 Palette 850 069 070 862.svg");
    
    shapeLogo = loadShape("LOGO.svg");
    
    pgPreview = createGraphics(pageWidth, pageHeight);
    
    fontTitle = createFont("HankenGrotesk-VariableFont_wght.ttf", 13);
    fontText = createFont("HankenGrotesk-VariableFont_wght.ttf", 10);
    
    luminance = loadJSONObject("luminance.json");
    //println(luminance);
    
    //TEST preview
    //paletteFilename = "2024-05-13 202302 PaletteFake 070 820 739 850.svg";
    //shape = loadShape(palettesFolder + paletteFilename);
    //previewPage(paletteFilename);
}


void draw() {
    
    background(255);
    
    image(pgPreview, 0, 0);
    
    //monitorFolder();
    
    delay(1000);
}

void previewPage(String paletteFilename) {
    
    //Draw into preview graphic
    pgPreview.beginDraw();
    pgPreview.clear();
    drawPage(pgPreview, paletteFilename);
    pgPreview.endDraw();
}


String exportPage(String paletteFilename) {
    //page filename is the same as palette, but with .pdf extension
    String pageFilename = paletteFilename.replace(".svg", ".pdf");
    String pagePath = archivesFolder + pageFilename;
    
    //create PDF forA5 format
    PGraphicsPDF pdf = (PGraphicsPDF) createGraphics(pageWidth, pageHeight, PDF, pagePath);
    pdf.beginDraw();
    drawPage(pdf, paletteFilename);
    pdf.dispose();
    pdf.endDraw();
    
    pdf = null;
    
    println("Page saved to " + pagePath);
    
    return pagePath;
}

void drawPage(PGraphics page, String paletteFilename) {
    
    // Logo
    page.shapeMode(CORNER);
    page.shape(shapeLogo, 0.7 * cm, 0.5 * cm);
    
    // palette
    page.shapeMode(CENTER);
    float shapeScale = 0.51;
    page.shape(shape, page.width / 2, page.height * 0.4, shape.width * shapeScale, shape.height * shapeScale);
    
    // Luminance
    page.fill(0);
    page.textFont(fontTitle);
    page.text("LUMINANCE6901", 0.7 * cm, 15 * cm);
    
    // Extract the 4 references from filename(ex : 2024 - 05 - 13 202302 Palette 850 069 070 862.svg ->[850, 069, 070, 862])
    String[] parts = splitTokens(paletteFilename.replace(".svg", ""), " ");
    String[] refs = subset(parts, 3, 4);
    
    // Draw the 4 references
    page.textFont(fontText);
    drawRef(page, refs[0], 0.7 * cm, 16 * cm);
    drawRef(page, refs[1], 0.52 * page.width, 16 * cm);
    drawRef(page, refs[2], 0.7 * cm, 18.8 * cm);
    drawRef(page, refs[3], 0.52 * page.width, 18.8 * cm);
}

void drawRef(PGraphics page, String ref, float xRef, float yRef) {
    
    JSONObject refLuminance = luminance.getJSONObject(ref);
    JSONObject hsb = refLuminance.getJSONObject("hsb");
    
    //Draw the reference
    page.colorMode(HSB);
    println(hsb.getInt("hue"), hsb.getInt("saturation"), hsb.getInt("brightness"));
    page.fill(hsb.getInt("hue"), hsb.getInt("saturation"), hsb.getInt("brightness"));
    page.text(ref + "\n" + refLuminance.getString("text"), xRef, yRef);
}

void keyPressed() {
    
    switch(key) {
        case'x':
        exportPage(paletteFilename);
        break;
        case 'm':
            monitorFolder();
            break;
    }
}

void monitorFolder() {
    println("Monitoring folder " + palettesFolder);
    
    //Listall files in the downloads folder
    File dir = new File(palettesFolder);
    File[]files = dir.listFiles();
    
    //Check if there are files in the downloads folder
    if (files.length > 0) {
        //Iterate over all files in the downloads folder
        for (int i = 0; i < files.length; i++) {
            //Check if the file is a file
            if (files[i].isFile()) {
                //Check if the file name matches thepattern
                if (files[i].getName().matches(".*Palette \\d\\d\\d \\d\\d\\d \\d\\d\\d \\d\\d\\d\\.svg")) {
                    
                    println(files[i].getName() + " matches the pattern");
                    
                    // preview
                    paletteFilename = files[i].getName();
                    shape = loadShape(palettesFolder + paletteFilename);
                    previewPage(paletteFilename);
                    
                    // export page
                    String pagePath = exportPage(paletteFilename);
                    
                    // Print the page
                    String[]args = new String[0];
                    args = append(args, "lp");
                    // args = append(args, "-o");
                    //args =append(args, "media=Custom."+ pageWidth + "x" + pageHeight + "cm");
                    // args = append(args, "-o");
                    // args = append(args, "scaling=100");
                    args = append(args, pagePath);
                    println(join(args, " "));
                    Process p = exec(args);
                    //Process p = exec("pwd");
                    
                    try {
                        int result = p.waitFor();
                        println("the process returned " + result);
                    } 
                    catch(InterruptedException e) {
                        println(e.toString());
                    }
                    
                    
                    // Move paletteFilename from palettesFolder to archivesFolder
                    File file = new File(palettesFolder + paletteFilename);
                    File fileDest = new File(archivesFolder + paletteFilename);
                    file.renameTo(fileDest);


                    
                    //Copythe file to the archives folder
                    // File file = new File(archivesFolder + "/" + files[i].getName());
                    // try {
                    //     File.copy(files[i].toPath(), file.toPath());
                // } catch(IOException e) {
                    //     e.printStackTrace();
                // }
                    
                    //Createa pdf file with the samename as the svg file
                    // StringpdfName = file.getName().replace(".svg", ".pdf");
                    // String[] command = {"inkscape", "--export-pdf=" + archivesFolder + "/" + pdfName, archivesFolder + "/" + file.getName()};
                    // try {
                    //     Process process = new ProcessBuilder(command).start();
                    //     process.waitFor();
                // } catch(IOException e) {
                    //     e.printStackTrace();
                // } catch(InterruptedException e) {
                    //     e.printStackTrace();
                // }
                    
                    //Print the pdf file
                    // PDDocument document = null;
                    // try {
                    //     document = PDDocument.load(new File(archivesFolder + "/" + pdfName));
                    //     PrinterJob job = PrinterJob.getPrinterJob();
                    //     job.setPageable(new PDFPageable(document));
                    //     if (job.printDialog()) {
                    //      job.print();
                    //  }
                // } catch(IOException e) {
                    //     e.printStackTrace();
                // } catch(PrinterException e) {
                    //     e.printStackTrace();
                // } finally {
                    //     if (document != null) {
                    //      try {
                    //      document.close();
                    //  } catch(IOException e) {
                    //      e.printStackTrace();
                    //  }
                    //  }
                // }
                }
            }
        }
    }
    println("Done");
}
