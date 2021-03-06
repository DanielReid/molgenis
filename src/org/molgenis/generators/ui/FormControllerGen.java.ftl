<#--#####################################################################
Generate Table Data Gateway
* One table per concrete class
* One table per class hierarchy root (ensures id's and types)
* Associations map onto the hierarchy root
#####################################################################-->
<#include "GeneratorHelper.ftl">
<#assign entity=JavaName(form.getRecord())>
<#--#####################################################################-->
<#--                                                                   ##-->
<#--         START OF THE OUTPUT                                       ##-->
<#--                                                                   ##-->
<#--#####################################################################-->
/* File:        ${Name(model)}/screen/${form.getName()}.java
 * Copyright:   GBIC 2000-${year?c}, all rights reserved
 * Date:        ${date}
 * 
 * generator:   ${generator} ${version}
 *
 * 
 * THIS FILE HAS BEEN GENERATED, PLEASE DO NOT EDIT!
 */
package ${package};

// jdk
import java.util.Vector;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

// molgenis
import org.molgenis.framework.db.DatabaseException;
import org.molgenis.framework.db.QueryRule.Operator;
import org.molgenis.framework.db.QueryRule;

import org.molgenis.framework.ui.ScreenModel;
import org.molgenis.framework.ui.ScreenController;
import org.molgenis.framework.ui.FormModel;
import org.molgenis.framework.ui.FormController;
import org.molgenis.framework.ui.FormModel.ParentFilter;
import org.molgenis.framework.ui.html.*;


${imports(model, model.getEntity(entity), "")}
${imports(model, model.getEntity(entity), "csv", "CsvReader")}
${imports(model, model.getEntity(entity), "ui", "Form")}

<#if parent_form?exists>
//imports parent forms
<#assign xrefentity = parent_form.getRecord()>
import ${xrefentity.getNamespace()}.${Name(xrefentity)};
</#if>

/**
 *
 */
public class ${JavaName(form.className)}FormController extends FormController<${entity}>
{
	private static final long serialVersionUID = 1L;
	
	public ${JavaName(form.className)}FormController()
	{
		this(null);
	}
	
	public ${JavaName(form.className)}FormController(ScreenController<?> parent)
	{
		super( "${form.getVelocityName()}", parent );
		getModel().setLabel("${form.label}");
		getModel().setLimit(${form.limit});
		<#if form.header?exists>getModel().setHeader("${form.header}");</#if>

		<#if form.sortby?exists>
		//sort is a bit hacky awaiting redesign of the Form classes
		try
		{
			((FormController)this).getPager().setOrderByField("${form.sortby}".toLowerCase());
			((FormController)this).getPager().setOrderByOperator(Operator.SORT${form.sortorder});
			this.getModel().setSort("${form.sortby}");
		}
		catch (DatabaseException e)
		{
			e.printStackTrace();
		}
		</#if>	
		getModel().setMode(FormModel.Mode.${form.viewType});
		getModel().setCsvReader(new ${entity}CsvReader());

<#-- parent form filtering -->
<#assign parent_xref = false>		
<#if parent_form?exists>
<#assign xrefentity = Name(parent_form.getRecord())>		
<#list form.getRecord().getAllFields() as field>
	<#--if subform entity refers to parent form entity: show only records that point to parent record-->
	<#--if multiple references exist, then use union, so 'OR' in query rule-->
	<#if field.getType() == "xref" || field.getType() == "mref">
		<#list superclasses(parent_form.getRecord()) as parent_entity>
			<#if parent_entity.getName() == field.xrefEntityName>
		//filter on <#if field.getType() == "mref">ANY </#if>subform_entity.${name(field)} == parentform_entity.${name(field.xrefField)}
		getModel().getParentFilters().add(new ParentFilter("${parent_form.name}","${SqlName(field.xrefField)}",Arrays.asList("${csv(field.xrefLabelNames)}".split(",")),"${SqlName(name(field))}"));
			</#if>
		</#list>
	</#if>
</#list>
<#--parent to subform xrefs-->		
<#list parent_form.getRecord().getAllFields() as field>
	<#--if parent entity refers to subform form entity: show only records that are pointed to by parent record-->
	<#--if multiple references exist, then use union, so 'OR' in query rule-->
	<#if field.getType() == "xref" || field.getType() == "mref">
		<#list superclasses(form.getRecord()) as subform_entity>
			<#if subform_entity.getName() == field.xrefEntityName>
		//filter on subform_entity.${name(field.xrefField)} == <#if field.getType() == "mref">ANY </#if> parentform_entity.${name(field)}
		getModel().getParentFilters().add(new ParentFilter("${parent_form.name}","${SqlName(name(field))}",Arrays.asList("${csv(field.xrefLabelNames)}".split(",")),"${SqlName(field.xrefField)}"));		
			</#if>
		</#list>
	</#if>
</#list>
</#if>	
<#list form.commands as command>
		getModel().addCommand(new ${command}(this));
</#list>		
<#if form.readOnly>
		getModel().setReadonly(true);
</#if>

<#list form.getChildren() as subscreen>
		<#assign screentype = Name(subscreen.getType().toString()?lower_case) />
		<#if screentype == "Form"><#assign screentype = "FormController"/></#if>
		new ${package}.${JavaName(subscreen)}${screentype}(this);
</#list>	

<#if form.hideFields?size &gt; 0>
		getModel().setUserHiddenColumns(Arrays.asList(new String[]{${csvQuotedEntity(entity, form.hideFields)}}));
</#if>	

<#list form.getRecord().getAllFields() as field>
	<#if field.getType() == "xref" || field.getType() == "mref">
		getModel().addCommand(new org.molgenis.framework.ui.commands.AddXrefCommand("${entity}_${field.getName()}", this, new ${JavaName(field.getXrefEntityName())}(), new ${JavaName(field.getXrefEntityName())}Form()));
	</#if>
</#list>
	}
	
	@Override
	public HtmlForm getInputs(${entity} entity, boolean newrecord)
	{
	
		${JavaName(entity)}Form form = new ${JavaName(entity)}Form(entity);
		form.setNewRecord(newrecord);
		form.setReadonly(getModel().isReadonly());
		form.setHiddenColumns(getModel().getUserHiddenColumns());
		<#if form.compactView?size &gt; 0>form.setCompactView(Arrays.asList(new String[]{${csvQuoted(form.compactView)}}));</#if>
		return form;
	}
	
	public void resetSystemHiddenColumns()
	{
		Vector<String> systemHiddenColumns = new Vector<String>();
<#list form.getRecord().getAllFields() as field>
	<#if field.isHidden() || field.hidden>
		systemHiddenColumns.add("${name(field)}");
	</#if>
</#list>
        getModel().setSystemHiddenColumns(systemHiddenColumns);
	}

	@Override	
	public String getSearchField(String fieldName)
	{
<#list form.getRecord().getAllFields() as field>
	<#if field.type="xref" || field.type="mref">
		<#list field.xrefLabelNames?reverse as label>
		if(fieldName.equals("${field.name}")) return "${field.name}_${label}";
		</#list>
	</#if>
</#list>	
		return fieldName;
	}	
	
	@Override
	public void resetCompactView()
	{
		ArrayList<String> compactView = new ArrayList<String>();
<#list form.getCompactView() as field_name>
		compactView.add("${field_name}");
</#list>	
        getModel().setCompactView(compactView);
	}
	
	@Override
	public Class<${entity}> getEntityClass()
	{
		return new ${JavaName(entity)}Form().getEntityClass();
	}
	
	@Override
	public Vector<String> getHeaders()
	{
		return new ${JavaName(entity)}Form().getHeaders();
	}
}