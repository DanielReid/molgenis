package org.molgenis.framework.db.jpa;

import java.util.List;
import javax.persistence.EntityManager;
import org.hibernate.Criteria;
import org.hibernate.Session;
import org.hibernate.criterion.Example;
import org.hibernate.ejb.Ejb3Configuration;
import org.hibernate.tool.hbm2ddl.SchemaExport;
import org.molgenis.util.Entity;

/**
 * @author joris lops
 */
public class HibernateImp implements JpaFramework {
    @Override
    public <E extends Entity> List<E> findByExample(EntityManager em, E example) {
        Session session = (Session) em.getDelegate();
        Example customerExample = Example.create(example).excludeZeroes();
        Criteria criteria = session.createCriteria(example.getClass()).add(customerExample);
        @SuppressWarnings("unchecked")
		List<E> list = (List<E>)criteria.list();
		return list;
    }

    public void createTables(String persistenceUnitName) {
        Ejb3Configuration cfg = new Ejb3Configuration();
        cfg.configure(persistenceUnitName, null);
        SchemaExport schemaExport = new SchemaExport(cfg.getHibernateConfiguration());
        schemaExport.setOutputFile("schema.sql");
        schemaExport.create(true, true);
    }

    public void dropTables(String persistenceUnitName) {
        Ejb3Configuration cfg = new Ejb3Configuration();
        cfg.configure("molgenis_test", null);
        SchemaExport schemaExport = new SchemaExport(cfg.getHibernateConfiguration());
        schemaExport.setOutputFile("schema.sql");
        schemaExport.drop(true, true);
    }
}