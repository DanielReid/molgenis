package org.molgenis.generators.excel;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.molgenis.MolgenisOptions;
import org.molgenis.generators.sql.MySqlCreateClassPerTableGen;
import org.molgenis.model.MolgenisModel;
import org.molgenis.model.elements.Entity;
import org.molgenis.model.elements.Model;

import freemarker.template.Template;

public class ImportWizardExcelPrognosisGen extends MySqlCreateClassPerTableGen
{
	public static final transient Logger logger = Logger.getLogger(ImportWizardExcelPrognosisGen.class);
	
	@Override
	public String getDescription()
	{
		return "Generates a prognosis report maker for the generic data import wizard using Excel files";
	}
	
	@Override
	public void generate(Model model, MolgenisOptions options)
			throws Exception
	{
		Template template = createTemplate( "/"+this.getClass().getSimpleName()+".java.ftl" );
		Map<String, Object> templateArgs = createTemplateArguments(options);
		
		List<Entity> entityList = model.getEntities();
		entityList = MolgenisModel.sortEntitiesByDependency(entityList,model); //side effect?
		//String packageName = this.getClass().getPackage().toString().substring(Generator.class.getPackage().toString().length());

		File target = new File( this.getSourcePath(options) + APP_DIR+"/ImportWizardExcelPrognosis.java" );
		target.getParentFile().mkdirs();
		
		templateArgs.put( "model", model );
		templateArgs.put("entities",entityList);
		templateArgs.put("package", APP_DIR);
		OutputStream targetOut = new FileOutputStream( target );
		template.process( templateArgs, new OutputStreamWriter( targetOut ) );
		targetOut.close();
		
		logger.info("generated " + target);
	}
}
